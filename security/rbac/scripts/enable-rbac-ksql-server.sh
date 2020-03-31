#!/bin/bash


################################################################################
# Overview
################################################################################
#
################################################################################

# Source library
. ../../../utils/helper.sh
. ./rbac_lib.sh

check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

. ../config/local-demo.env
ORIGINAL_CONFIGS_DIR=/tmp/original_configs
DELTA_CONFIGS_DIR=../delta_configs
FILENAME=ksql-server.properties
create_temp_configs $CONFLUENT_HOME/etc/ksqldb/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic
# - Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to Topic:${KSQL_SERVICE_ID}_ksql_processing_log
# - Start KSQL
# - Grant principal User:$USER_ADMIN_KSQL the SecurityAdmin role to the KSQL Cluster
# - Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to KsqlCluster:ksql-cluster
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

# Use the default KSQL app identifier
KSQL_SERVICE_ID=rbac-ksql

echo -e "\n# Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to Topic:${KSQL_SERVICE_ID}ksql_processing_log"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up KSQL server"
confluent local start ksql-server

echo "Sleeping 10 seconds"
sleep 10

echo -e "\n# Grant principal User:$USER_ADMIN_KSQL the SecurityAdmin role to the KSQL Cluster to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

echo -e "\n# Grant principal User:$USER_ADMIN_KSQL the ResourceOwner role to KsqlCluster:ksql-cluster"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

echo -e "\n# List the role bindings for the principal User:$USER_ADMIN_KSQL"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_ADMIN_KSQL to the KSQL cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID


##################################################
# KSQL client functions
# Note: KSQL server executes many of the commands that the KSQL client issues
# - Grant principal User:${USER_KSQL} the DeveloperWrite role to KsqlCluster:ksql-cluster
# - Grant principal User:${USER_KSQL} the DeveloperRead role to Topic:$TOPIC1
# - Grant principal User:${USER_KSQL} the DeveloperRead role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix
# - Grant principal User:${USER_KSQL} the DeveloperRead role to Topic:${KSQL_SERVICE_ID}ksql_processing_log
# - Grant principal User:${USER_ADMIN_KSQL} the DeveloperRead role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
# - Grant principal User:${USER_ADMIN_KSQL} the DeveloperRead role to Topic:$TOPIC1"
# - Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to TransactionalId:${KSQL_SERVICE_ID}
# - Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${KSQL_SERVICE_ID}transient prefix
# - Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${KSQL_SERVICE_ID}transient prefix
# - Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${CSAS_STREAM1}
# - Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${CSAS_STREAM1}
# - Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${CTAS_TABLE1}
# - Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${CTAS_TABLE1}
# - Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
# - List the role bindings for the principal User:${USER_KSQL}
# - List the role bindings for the principal User:$USER_ADMIN_KSQL"
##################################################

echo -e "\n# Grant principal User:${USER_KSQL} the DeveloperWrite role to KsqlCluster:ksql-cluster"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperWrite --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperWrite --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

echo -e "\n# Grant principal User:${USER_KSQL} the DeveloperRead role to Topic:$TOPIC1"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# KSQL CLI: list topics and print messages from topic $TOPIC1"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
list topics;
PRINT '$TOPIC1' FROM BEGINNING LIMIT 3;
exit ;
EOF

echo -e "\n# Grant principal User:${USER_KSQL} the DeveloperRead role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_KSQL} the DeveloperRead role to Topic:${KSQL_SERVICE_ID}ksql_processing_log"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the DeveloperRead role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the DeveloperRead role to Topic:$TOPIC1"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to TransactionalId:${KSQL_SERVICE_ID}"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource TransactionalId:${KSQL_SERVICE_ID} --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource TransactionalId:${KSQL_SERVICE_ID} --kafka-cluster-id $KAFKA_CLUSTER_ID

STREAM=stream1
echo -e "\n# KSQL CLI: create a new stream $STREAM and select * from that stream"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
SET 'auto.offset.reset'='earliest';
CREATE STREAM $STREAM (id varchar) WITH (kafka_topic='$TOPIC1', value_format='delimited');
SELECT * FROM $STREAM EMIT CHANGES LIMIT 3;
exit ;
EOF

echo -e "\n# KSQL CLI: create a new table and select * from that table, before authorization (should fail)"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
CREATE TABLE table1 (id varchar) WITH (kafka_topic='$TOPIC1', value_format='delimited', key='id');
SELECT * FROM table1 EMIT CHANGES LIMIT 1;
exit ;
EOF

echo -e "\n# Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${KSQL_SERVICE_ID}transient prefix"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${KSQL_SERVICE_ID}transient prefix"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# KSQL CLI: create a new table and select * from that table, after authorization (should pass)"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
SET 'auto.offset.reset'='earliest';
CREATE TABLE table2 (id varchar) WITH (kafka_topic='$TOPIC1', value_format='delimited', key='id');
SELECT * FROM table2 EMIT CHANGES LIMIT 3;
exit ;
EOF

CSAS_STREAM1=CSAS_STREAM1
echo -e "\n# Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${CSAS_STREAM1}"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${CSAS_STREAM1}"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# KSQL CLI: create a new stream as select from another stream and select * from that stream, after authorization (should pass)"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
SET 'auto.offset.reset'='earliest';
CREATE STREAM $CSAS_STREAM1 AS SELECT * FROM stream1;
SELECT * FROM $CSAS_STREAM1 EMIT CHANGES LIMIT 3;
exit ;
EOF

CTAS_TABLE1=CTAS_TABLE1
echo -e "\n# Grant principal User:${USER_KSQL} the ResourceOwner role to Topic:${CTAS_TABLE1}"
echo "confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:${CTAS_TABLE1}"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:${USER_ADMIN_KSQL} the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
echo "confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# KSQL CLI: create a new table as select from another table and select * from that table, after authorization (should pass)"
echo "ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088"
echo
ksql -u $USER_KSQL -p ${USER_KSQL}1 http://localhost:8088 <<EOF
SET 'auto.offset.reset'='earliest';
CREATE TABLE $CTAS_TABLE1 AS SELECT * FROM table1;
SELECT * FROM $CTAS_TABLE1 EMIT CHANGES LIMIT 3;
exit ;
EOF

echo -e "\n# List the role bindings for the principal User:$USER_ADMIN_KSQL"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_ADMIN_KSQL to the KSQL cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

echo -e "\n# List the role bindings for the principal User:$USER_KSQL"
echo "confluent iam rolebinding list --principal User:$USER_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_KSQL to the KSQL cluster"
echo "confluent iam rolebinding list --principal User:$USER_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID"
confluent iam rolebinding list --principal User:$USER_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/ksqldb/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
