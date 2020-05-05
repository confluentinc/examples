#!/bin/bash

################################################################
# Source Confluent Platform versions
################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. "$DIR/config.env"
. "$DIR/helper.sh"


################################################################
# Library of functions
################################################################

function cloud_create_demo_stack() {
  RANDOM_NUM=$1
  echo "RANDOM_NUM: $RANDOM_NUM"

  ENVIRONMENT_NAME="demo-env-$RANDOM_NUM"
  ENVIRONMENT=$(cloud_create_and_use_environment $ENVIRONMENT_NAME)
  echo "ENVIRONMENT: $ENVIRONMENT, ENVIRONMENT_NAME: $ENVIRONMENT_NAME"

  SERVICE_NAME="demo-app-$RANDOM_NUM"
  SERVICE_ACCOUNT_ID=$(cloud_create_service_account $SERVICE_NAME)
  echo "SERVICE_ACCOUNT_ID: $SERVICE_ACCOUNT_ID"

  CLUSTER_NAME=demo-kafka-cluster-$RANDOM_NUM
  CLUSTER_CLOUD="${CLUSTER_CLOUD:-aws}"
  CLUSTER_REGION="${CLUSTER_REGION:-us-west-2}"
  CLUSTER=$(cloud_create_and_use_cluster $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION)
  BOOTSTRAP_SERVERS=$(ccloud kafka cluster describe $CLUSTER -o json | jq -r ".endpoint" | cut -c 12-)
  CLUSTER_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $CLUSTER)
  echo "CLUSTER: $CLUSTER, BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS, CLUSTER_CREDS: $CLUSTER_CREDS"

  MAX_WAIT=720
  echo
  echo "Waiting for Confluent Cloud cluster to be ready and for credentials to propagate"
  retry $MAX_WAIT check_ccloud_cluster_ready || exit 1
  # Estimating another 60s wait still sometimes required
  sleep 60
  printf "\n\n"

  SCHEMA_REGISTRY_GEO="${SCHEMA_REGISTRY_GEO:-us}"
  SCHEMA_REGISTRY=$(cloud_enable_schema_registry $CLUSTER_CLOUD $SCHEMA_REGISTRY_GEO)
  SCHEMA_REGISTRY_ENDPOINT=$(ccloud schema-registry cluster describe -o json | jq -r ".endpoint_url")
  SCHEMA_REGISTRY_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $SCHEMA_REGISTRY)
  echo "SCHEMA_REGISTRY: $SCHEMA_REGISTRY, SCHEMA_REGISTRY_ENDPOINT: $SCHEMA_REGISTRY_ENDPOINT, SCHEMA_REGISTRY_CREDS: $SCHEMA_REGISTRY_CREDS"

  KSQL_NAME="demo-ksql-$RANDOM_NUM"
  KSQL=$(cloud_create_ksql_app $KSQL_NAME $CLUSTER)
  KSQL_ENDPOINT=$(ccloud ksql app describe $KSQL -o json | jq -r ".endpoint")
  KSQL_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $KSQL)
  echo "KSQL: $KSQL, KSQL_ENDPOINT: $KSQL_ENDPOINT, KSQL_CREDS: $KSQL_CREDS"

  cloud_create_wildcard_acls $SERVICE_ACCOUNT_ID
  ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID

  CLIENT_CONFIG="/tmp/client-$RANDOM_NUM.config"
  cat <<EOF > $CLIENT_CONFIG
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="`echo $CLUSTER_CREDS | awk -F: '{print $1}'`" password\="`echo $CLUSTER_CREDS | awk -F: '{print $2}'`";
basic.auth.credentials.source=USER_INFO
schema.registry.url=${SCHEMA_REGISTRY_ENDPOINT}
schema.registry.basic.auth.user.info=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'`:`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
ksql.endpoint=${KSQL_ENDPOINT}
ksql.basic.auth.user.info=`echo $KSQL_CREDS | awk -F: '{print $1}'`:`echo $KSQL_CREDS | awk -F: '{print $2}'`
EOF
  echo "$CLIENT_CONFIG:"
  cat $CLIENT_CONFIG

  return 0
}

function cloud_delete_demo_stack() {
  RANDOM_NUM=$1

  KSQL=$(ccloud ksql app list | grep demo-ksql-$RANDOM_NUM | awk '{print $1;}')
  echo "KSQL: $KSQL"
  ccloud ksql app delete $KSQL

  cloud_delete_demo_stack_acls $SERVICE_ACCOUNT_ID

  CLUSTER=$(ccloud kafka cluster list | grep demo-kafka-cluster-$RANDOM_NUM | tr -d '\*' | awk '{print $1;}')
  echo "CLUSTER: $CLUSTER"
  ccloud kafka cluster delete $CLUSTER

  SERVICE_ACCOUNT_ID=$(ccloud service-account list | grep demo-app-$RANDOM_NUM | awk '{print $1;}')
  echo "SERVICE_ACCOUNT_ID: $SERVICE_ACCOUNT_ID"
  ccloud service-account delete $SERVICE_ACCOUNT_ID 

  ENVIRONMENT=$(ccloud environment list | grep demo-env-$RANDOM_NUM | tr -d '\*' | awk '{print $1;}')
  echo "ENVIRONMENT: $ENVIRONMENT"
  ccloud environment delete $ENVIRONMENT

  CLIENT_CONFIG="/tmp/client-$RANDOM_NUM.config"
  rm -f $CLIENT_CONFIG

  return 0
}
