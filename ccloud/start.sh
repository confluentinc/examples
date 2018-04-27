#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 4.1 || exit 
check_ccloud || exit

if ! is_ce ; then
  echo "This demo uses Confluent Replicator which requires Confluent Enterprise, however this host is running Confluent Open Source. Exiting"
  exit 1
fi

./stop.sh

get_ksql_ui
confluent start
CONFLUENT_CURRENT=`confluent current`

# Confluent Cloud configuration
CCLOUD_CONFIG=$HOME/.ccloud/config

# Build configuration file with CCloud connection parameters and
# Confluent Monitoring Interceptors for Streams Monitoring in Confluent Control Center
INTERCEPTORS_CCLOUD_CONFIG=$CONFLUENT_CURRENT/control-center/interceptors-ccloud.config
while read -r line
do
  echo $line >> $INTERCEPTORS_CCLOUD_CONFIG
  if is_ce; then
    if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' || ${line:0:9} == 'bootstrap' ]]; then
      echo "confluent.monitoring.interceptor.$line" >> $INTERCEPTORS_CCLOUD_CONFIG
    fi
  fi
done < "$CCLOUD_CONFIG"

# Schema Registry instance for Confluent Cloud
# Set this new Schema Registry listener to port $SR_LISTENER instead of default 8081 which is already in use
SR_LISTENER=8085
SR_CONFIG=$CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.properties
cp $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties $SR_CONFIG
sed -i '' "s/listeners=http:\/\/0.0.0.0:8081/listeners=http:\/\/0.0.0.0:$SR_LISTENER/g" $SR_CONFIG
# Avoid clash between two local SR instances
sed -i '' 's/kafkastore.connection.url=localhost:2181/#kafkastore.connection.url=localhost:2181/g' $SR_CONFIG
while read -r line
do
  if [[ ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' && ! "$line" =~ "SASL_SSL:" ]]; then
      # Schema Registry requires security protocol, i.e. "SASL_SSL://", in kafkastore.bootstrap.servers
      line=${line/=/=SASL_SSL:\/\/}
      line=${line/,/,SASL_SSL:\/\/}
    fi
    echo "kafkastore.$line" >> $SR_CONFIG
  fi
done < "$CCLOUD_CONFIG"
echo "Starting Confluent Schema Registry for Confluent Cloud and sleeping 40 seconds"
schema-registry-start $SR_CONFIG > $CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.stdout 2>&1 &
sleep 40

ccloud topic describe _schemas
if [[ $? == 1 ]]; then
  echo "ERROR: Schema Registry could not create topic '_schemas' in Confluent Cloud. Please troubleshoot"
  exit
fi

# Produce pageviews data in local cluster
kafka-topics --zookeeper localhost:2181 --create --topic pageviews --partitions 12 --replication-factor 1
ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=http://localhost:$SR_LISTENER &>/dev/null &
sleep 5

# Produce users data in CCloud cluster
ccloud topic create users
ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=http://localhost:$SR_LISTENER propertiesFile=$CCLOUD_CONFIG &>/dev/null &

# Stop the Connect that starts with Confluent CLI to run Replicator that includes its own Connect workers
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9

# Replicate local topic `pageviews` to Confluent Cloud topics `pageviews.replica`
ccloud topic create pageviews.replica
PRODUCER_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud-producer.properties
cp $INTERCEPTORS_CCLOUD_CONFIG $PRODUCER_PROPERTIES
if is_ce; then
  echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $PRODUCER_PROPERTIES
fi
CONSUMER_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud-consumer.properties
echo "bootstrap.servers=localhost:9092" > $CONSUMER_PROPERTIES
REPLICATOR_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud.properties
echo "topic.whitelist=pageviews" > $REPLICATOR_PROPERTIES
echo "topic.rename.format=\${topic}.replica" >> $REPLICATOR_PROPERTIES
echo "topic.config.sync=false" >> $REPLICATOR_PROPERTIES
echo "Starting Confluent Replicator and sleeping 60 seconds"
replicator --cluster.id replicator-to-ccloud --consumer.config $CONSUMER_PROPERTIES --producer.config $PRODUCER_PROPERTIES --replication.config $REPLICATOR_PROPERTIES > $CONFLUENT_CURRENT/connect/replicator-to-ccloud.stdout 2>&1 &
sleep 60

# Local KSQL Server connecting to Confluent Cloud
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
KSQL_SERVER_CONFIG=$CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.properties
cp $INTERCEPTORS_CCLOUD_CONFIG $KSQL_SERVER_CONFIG
if is_ce; then
  cat <<EOF >> $KSQL_SERVER_CONFIG
producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor
consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor
EOF
fi
# Set this new KSQL Server listener to port $KSQL_LISTENER instead of default 8088 which is already in use
KSQL_LISTENER=8089
cat <<EOF >> $KSQL_SERVER_CONFIG
listeners=http://localhost:$KSQL_LISTENER
ksql.server.ui.enabled=true
auto.offset.reset=earliest
commit.interval.ms=0
cache.max.bytes.buffering=0
auto.offset.reset=earliest
ksql.sink.replicas=3
replication.factor=3
ksql.schema.registry.url=http://localhost:$SR_LISTENER
state.dir=$CONFLUENT_CURRENT/ksql-server/data-ccloud/kafka-streams
EOF
echo "Starting KSQL Server for Confluent Cloud and sleeping 25 seconds"
ksql-server-start $KSQL_SERVER_CONFIG > $CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.stdout 2>&1 &
sleep 25

ksql http://localhost:$KSQL_LISTENER <<EOF
run script 'ksql.commands';
exit ;
EOF

# Confluent Control Center to manage and monitor Confluent Cloud
if is_ce; then
  C3_CONFIG=$CONFLUENT_CURRENT/control-center/control-center-ccloud.properties
  cp $CONFLUENT_HOME/etc/confluent-control-center/control-center-production.properties $C3_CONFIG
  # Stop the Control Center that starts with Confluent CLI to run Control Center to CCloud
  jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
  while read -r line
    do
    if [[ ${line:0:1} != '#' ]]; then
      echo "$line" >> $C3_CONFIG
      if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' || ${line:0:9} == 'bootstrap' ]]; then
        echo "confluent.controlcenter.streams.$line" >> $C3_CONFIG
      fi
    fi
  done < "$CCLOUD_CONFIG"
  echo "confluent.controlcenter.connect.cluster=localhost:8083" >> $C3_CONFIG
  echo "confluent.controlcenter.data.dir=$CONFLUENT_CURRENT/control-center/data-ccloud" >> $C3_CONFIG
  control-center-start $C3_CONFIG > $CONFLUENT_CURRENT/control-center/control-center-ccloud.stdout 2>&1 &
fi

sleep 10
