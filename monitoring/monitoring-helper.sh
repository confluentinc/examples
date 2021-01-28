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
  if [[ $MONITOR_CP_DEMO ]]; then
    DOCKER_CMD="$DOCKER_CMD --project-directory $CP_DEMO_HOME -f docker-compose.cp-demo-extended.yml -f docker-compose.kafka-lag-exporter.yml -f docker-compose.node-exporter.yml"
  fi
  $DOCKER_CMD config > docker-compose.yml
  return 0
}


# This method does a job similar to realpath, but avoid that extra dependency.
# It returns fullpath for a given parameter to avoind using relative paths.
function fullpath() {
   fullpath=$(cd $1 && pwd -P)
   echo $fullpath
   cd $OLDPWD
}

function setup_cp_demo() {
  DEFAULT_CP_DEMO_HOME=$(fullpath ${MONITORING_STACK}/../../cp-demo)
  CP_DEMO_HOME=${CP_DEMO_HOME:-$DEFAULT_CP_DEMO_HOME}
  [ -d "${CP_DEMO_HOME}" ] || {
    echo "ERROR: ${CP_DEMO_HOME} does not exist. Have you cloned https://github.com/confluentinc/cp-demo? If cp-demo is not in ${CP_DEMO_HOME}, you can set CP_DEMO_HOME and try again."
    exit 1
  }
  CP_DEMO_VERSION=$(grep "CONFLUENT_DOCKER_TAG" "${CP_DEMO_HOME}/env_files/config.env")
  export COMPOSE_FILE="$CP_DEMO_HOME/docker-compose.yml:$MONITORING_STACK/docker-compose.override.yml"
}


function start_cp_demo_and_monitoring() {
  # Start cp-demo
  export MONITORING_STACK="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  setup_cp_demo
  echo -e "Launch cp-demo in $CP_DEMO_HOME (version $CP_DEMO_VERSION) and monitoring stack in $MONITORING_STACK"
  MONITOR_CP_DEMO=true
  source $CP_DEMO_HOME/scripts/env.sh
  cd docker-compose-files && create_monitoring_docker_compose
  (cd $CP_DEMO_HOME && ./scripts/start.sh)
  # Start setup for kafka lag exporter
  echo -e "Create user and certificates for kafkaLagExporter"
  KAFKA_LAG_EXPORTER="User:kafkaLagExporter"
  SECURITY_DIR="${MONITORING_STACK}/configs/security"
  mkdir -p $SECURITY_DIR
  (cd $SECURITY_DIR && rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12)
  (cd $SECURITY_DIR && $CP_DEMO_HOME/scripts/security/certs-create-per-user.sh kafkaLagExporter)
  echo -e "Create role binding for kafkaLagExporter"
  cd $CP_DEMO_HOME
  # Start up jmx metrics
  KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
  docker-compose exec tools bash -c "confluent iam rolebinding create \
      --principal $KAFKA_LAG_EXPORTER \
      --role SystemAdmin \
      --kafka-cluster-id $KAFKA_CLUSTER_ID"
  # Start up exporters, prometheus and grafana
  echo -e "Launch $MONITORING_STACK"
  cd docker-compose-files && docker-compose up -d prometheus node-exporter kafka-lag-exporter grafana ccloud-exporter
  # Inform user of where to login
  echo -e "\nView Grafana dashboards at (admin/password) ->"
  echo -e "http://localhost:3000"
}