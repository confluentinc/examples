#!/bin/bash

# Create targets to scrape
# ^ maybe do that during the demo

# if Cloud monitoring, check api secret and ccloud id set
# create monitoring dc file
# run monitoring dc file


# Create docker-compose
function create_monitoring_docker_compose(){
  DOCKER_CMD="docker-compose -f docker-compose.base.yml"
  if [[ $MONITOR_CLOUD ]]; then
    DOCKER_CMD="$DOCKER_CMD -f docker-compose.ccloud-exporter.yml"
    if [[ -z CCLOUD_API_KEY ]] && [[ -z CCLOUD_API_SECRET ]] && [[ -z CCLOUD_CLUSTER ]]; then
      echo "Please ensure these environment variables are set: CCLOUD_API_KEY, CCLOUD_API_SECRET, CCLOUD_CLUSTER"
      return 1
    fi
  fi
  if [[ $MONITOR_KAFKA_LAG ]]; then
    DOCKER_CMD="$DOCKER_CMD -f docker-compose.kafka-lag-exporter.yml"
  fi
  if [[ $MONITOR_NODE_EXPORTER ]]; then
    DOCKER_CMD="$DOCKER_CMD -f docker-compose.node-exporter.yml"
  fi
  $DOCKER_CMD config > docker-compose.yml
  return 0
}

# Setup kafka-lag-exporter
function kafka_lag_exporter_setup() {
  echo -e "Create user and certificates for kafkaLagExporter"
  KAFKA_LAG_EXPORTER="User:kafkaLagExporter"
  SECURITY_DIR="${MONITORING_STACK}/configs/security"
  mkdir -p $SECURITY_DIR
  (cd $SECURITY_DIR && rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12)
  # TODO figure out how to just pull certs-create-per-user.sh to decouple this from cp-demo
  (cd $SECURITY_DIR && $CP_DEMO_HOME/scripts/security/certs-create-per-user.sh kafkaLagExporter)

  echo -e "Create role binding for kafkaLagExporter"
  # TODO how should I decouple this from cp-demo?
  cd $CP_DEMO_HOME
  KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
  docker-compose exec tools bash -c "confluent iam rolebinding create \
      --principal $KAFKA_LAG_EXPORTER \
      --role SystemAdmin \
      --kafka-cluster-id $KAFKA_CLUSTER_ID"
}