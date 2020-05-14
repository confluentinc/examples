#!/bin/bash

################################################################
# Source Confluent Platform versions
################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. "$DIR/config.env"


################################################################
# Library of functions
################################################################

function prompt_continue_cloud_demo() {
  echo "This demo uses real Confluent Cloud resources."
  echo "To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it."
  read -p "Do you still want to run this script? [y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      exit 1
  fi

  return 0
}

function check_ccloud_binary() {
  if [[ $(type ccloud 2>&1) =~ "not found" ]]; then
    echo "'ccloud' is not found. Install Confluent Cloud CLI (https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli) and try again"
    exit 1
  fi
}

function check_ccloud_v1() {
  expected_version="0.2.0"

  check_ccloud_binary || exit 1

  actual_version=$(ccloud version | grep -i "version" | awk '{print $3;}')
  if ! [[ $actual_version =~ $expected_version ]]; then
    echo "This demo requires Confluent Cloud CLI version $expected_version but the running version is '$actual_version'. Please update your version and try again."
    exit 1
  fi

  return 0
}

function check_ccloud_v2() {

  check_ccloud_binary || exit 1

  if [[ -z $(ccloud version | grep "Go") ]]; then
    echo "This demo requires the new Confluent Cloud CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function check_ccloud_logged_in() {
  check_ccloud_v2 || exit 1

  if [[ "$(ccloud kafka cluster list 2>&1)" == "Error: You must log in to run that command." ]]; then
    echo "ERROR: Log into Confluent Cloud with the command 'ccloud login [--save]' before running the demo."
    exit 1
  fi

  return 0
}

function get_ccloud_version() {
  ccloud version | grep "^Version:" | cut -d':' -f2 | cut -d'v' -f2
}

function check_ccloud_version() {

  check_ccloud_binary || exit 1

  REQUIRED_CCLOUD_VER=${1:-"0.185.0"}
  CCLOUD_VER=$(get_ccloud_version)

  if version_gt $REQUIRED_CCLOUD_VER $CCLOUD_VER; then
    echo "ccloud version ${REQUIRED_CCLOUD_VER} or greater is required.  Current reported version: ${CCLOUD_VER}"
    echo 'To update run: ccloud update'
    exit 1
  fi
}

function check_cli_v2() {

  if [[ -z $(confluent version | grep "Go") ]]; then
    echo "This demo requires the new Confluent CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function check_aws() {
  if [[ $(type aws 2>&1) =~ "not found" ]]; then
    echo "AWS CLI is not found. Install AWS CLI and try again"
    exit 1
  fi

  return 0
}

function get_aws_cli_version() {
  version_major=$(aws --version 2>&1 | awk -F/ '{print $2;}' | head -c 1)
  if [[ "$version_major" -eq 2 ]]; then
    echo "2"
  else
    echo "1"
  fi
  return 0
}

function check_gsutil() {
  if [[ $(type gsutil 2>&1) =~ "not found" ]]; then
    echo "Google Cloud gsutil is not found. Install Google Cloud gsutil and try again"
    exit 1
  fi

  return 0
}

function check_az_tool() {
  if [[ $(type az 2>&1) =~ "not found" ]]; then
    echo "Azure CLI is not found. Install Azure CLI and try again"
    exit 1
  fi

  return 0
}

function validate_cloud_storage() {
  config=$1

  source $config
  storage=$DESTINATION_STORAGE

  if [[ "$storage" == "s3" ]]; then
    check_aws || exit 1
    check_s3_creds $S3_PROFILE $S3_BUCKET || exit 1
  elif [[ "$storage" == "gcs" ]]; then
    check_gsutil || exit 1
    check_gcp_creds $GCS_CREDENTIALS_FILE $GCS_BUCKET || exit 1
  elif [[ "$storage" == "az" ]]; then
    check_az_tool || exit 1
    check_az_creds $AZBLOB_STORAGE_ACCOUNT $AZBLOB_CONTAINER || exit 1
  else
    echo "Storage destination $storage is not valid.  Must be one of [s3|gcs|az]."
    exit 1
  fi

  return 0
}

function check_gcp_creds() {
  GCS_CREDENTIALS_FILE=$1
  GCS_BUCKET=$2

  if [[ -z "$GCS_CREDENTIALS_FILE" || -z "$GCS_BUCKET" ]]; then
    echo "ERROR: DESTINATION_STORAGE=gcs, but GCS_CREDENTIALS_FILE or GCS_BUCKET is not set.  Please set these parameters in config/demo.cfg and try again."
    exit 1
  fi

  gcloud auth activate-service-account --key-file $GCS_CREDENTIALS_FILE || {
    echo "ERROR: Cannot activate service account with key file $GCS_CREDENTIALS_FILE. Verify your credentials and try again."
    exit 1
  }

  # Create JSON-formatted string of the GCS credentials
  export GCS_CREDENTIALS=$(python ./stringify-gcp-credentials.py $GCS_CREDENTIALS_FILE)
  # Remove leading and trailing double quotes, otherwise connector creation from CLI fails
  GCS_CREDENTIALS=$(echo "${GCS_CREDENTIALS:1:${#GCS_CREDENTIALS}-2}")

  return 0
}

function check_az_creds() {
  AZBLOB_STORAGE_ACCOUNT=$1
  AZBLOB_CONTAINER=$2

  if [[ -z "$AZBLOB_STORAGE_ACCOUNT" || -z "$AZBLOB_CONTAINER" ]]; then
    echo "ERROR: DESTINATION_STORAGE=az, but AZBLOB_STORAGE_ACCOUNT or AZBLOB_CONTAINER is not set.  Please set these parameters in config/demo.cfg and try again."
    exit 1
  fi

  if [[ "$AZBLOB_STORAGE_ACCOUNT" == "default" ]]; then
    echo "ERROR: Azure Blob storage account name cannot be 'default'. Verify the value of the storage account name (did you create one?) in config/demo.cfg, as specified by the parameter AZBLOB_STORAGE_ACCOUNT, and try again."
    exit 1
  fi

  exists=$(az storage account check-name --name $AZBLOB_STORAGE_ACCOUNT | jq -r .reason)
  if [[ "$exists" != "AlreadyExists" ]]; then
    echo "ERROR: Azure Blob storage account name $AZBLOB_STORAGE_ACCOUNT does not exist. Check the value of AZBLOB_STORAGE_ACCOUNT in config/demo.cfg and try again."
    exit 1
  fi
  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
  if [[ "$AZBLOB_ACCOUNT_KEY" == "" ]]; then
    echo "ERROR: Cannot get the key for Azure Blob storage account name $AZBLOB_STORAGE_ACCOUNT. Check the value of AZBLOB_STORAGE_ACCOUNT in config/demo.cfg, and your key, and try again."
    exit 1
  fi

  return 0
}

function check_s3_creds() {
  S3_PROFILE=$1
  S3_BUCKET=$2

  if [[ -z "$S3_PROFILE" || -z "$S3_BUCKET" ]]; then
    echo "ERROR: DESTINATION_STORAGE=s3, but S3_PROFILE or S3_BUCKET is not set.  Please set these parameters in config/demo.cfg and try again."
    exit 1
  fi

  aws configure get aws_access_key_id --profile $S3_PROFILE 1>/dev/null || {
    echo "ERROR: Cannot determine aws_access_key_id from S3_PROFILE=$S3_PROFILE.  Verify your credentials and try again."
    exit 1
  }
  aws configure get aws_secret_access_key --profile $S3_PROFILE 1>/dev/null || {
    echo "ERROR: Cannot determine aws_secret_access_key from S3_PROFILE=$S3_PROFILE.  Verify your credentials and try again."
    exit 1
  }
  return 0
}

function validate_confluent_cloud_schema_registry() {
  auth=$1
  sr_endpoint=$2

  curl --silent -u $auth $sr_endpoint > /dev/null || {
    echo "ERROR: Could not validate credentials to Confluent Cloud Schema Registry. Please troubleshoot"
    exit 1
  }

  echo "Validated credentials to Confluent Cloud Schema Registry at $sr_endpoint"
  return 0
}


function cloud_create_and_use_environment() {
  ENVIRONMENT_NAME=$1

  OUTPUT=$(ccloud environment create $ENVIRONMENT_NAME -o json)
  if [[ $? != 0 ]]; then
    echo "ERROR: Failed to create environment $ENVIRONMENT_NAME. Please troubleshoot (maybe run ./clean.sh) and run again"
    exit 1
  fi
  ENVIRONMENT=$(echo "$OUTPUT" | jq -r ".id")
  ccloud environment use $ENVIRONMENT &>/dev/null

  echo $ENVIRONMENT

  return 0
}

function cloud_create_and_use_cluster() {
  CLUSTER_NAME=$1
  CLUSTER_CLOUD=$2
  CLUSTER_REGION=$3

  OUTPUT=$(ccloud kafka cluster create $CLUSTER_NAME --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION)
  CLUSTER=$(echo "$OUTPUT" | grep '| Id' | awk '{print $4;}')
  ccloud kafka cluster use $CLUSTER

  echo $CLUSTER

  return 0
}

function cloud_create_service_account() {
  SERVICE_NAME=$1

  OUTPUT=$(ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME  -o json)
  SERVICE_ACCOUNT_ID=$(echo "$OUTPUT" | jq -r ".id")

  echo $SERVICE_ACCOUNT_ID

  return 0
}

function cloud_enable_schema_registry() {
  SCHEMA_REGISTRY_CLOUD=$1
  SCHEMA_REGISTRY_GEO=$2

  OUTPUT=$(ccloud schema-registry cluster enable --cloud aws --geo us -o json)
  SCHEMA_REGISTRY=$(echo "$OUTPUT" | jq -r ".id")

  echo $SCHEMA_REGISTRY

  return 0
}

function cloud_create_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2

  OUTPUT=$(ccloud api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json)
  API_KEY_SA=$(echo "$OUTPUT" | jq -r ".key")
  API_SECRET_SA=$(echo "$OUTPUT" | jq -r ".secret")

  echo "${API_KEY_SA}:${API_SECRET_SA}"

  return 0
}

function cloud_create_ksql_app() {
  KSQL_NAME=$1
  CLUSTER=$2

  KSQL=$(ccloud ksql app create --cluster $CLUSTER -o json $KSQL_NAME | jq -r ".id")
  echo $KSQL

  return 0
}

function cloud_create_wildcard_acls() {
  SERVICE_ACCOUNT_ID=$1

  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --topic '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE_CONFIGS --topic '*'

  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --consumer-group '*'
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --consumer-group '*'

  return 0
}

function cloud_delete_demo_stack_acls() {
  SERVICE_ACCOUNT_ID=$1

  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --topic '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE_CONFIGS --topic '*'

  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --consumer-group '*'
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --consumer-group '*'

  return 0
}

function check_ccloud_config() {
  expected_configfile=$1

  if [[ ! -f "$expected_configfile" ]]; then
    echo "Confluent Cloud configuration file does not exist at $expected_configfile. Please create the configuration file with properties set to your Confluent Cloud cluster and try again."
    exit 1
  else
    cat "$CONFIG_FILE" | jq . &> /dev/null
    status=$?
    if [[ $status == 0 ]]; then
      echo "ERROR: File $CONFIG_FILE is not properly formatted as key=value pairs (did you accidentally point to the Confluent Cloud CLI 'config.json' file?--this will not work). Manually create the required properties file to connect to your Confluent Cloud cluster and then try again."
      echo "See https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html for more information"
      exit 1
    elif ! [[ $(grep "^\s*bootstrap.server" $expected_configfile) ]]; then
      echo "Missing 'bootstrap.server' in $expected_configfile. Please modify the configuration file with properties set to your Confluent Cloud cluster and try again."
      exit 1
    fi
  fi

  return 0
}

function validate_ccloud_ksql() {
  ksql_endpoint=$1
  ccloud_config_file=$2
  credentials=$3

  check_ccloud_logged_in || exit 1

  if [[ "$ksql_endpoint" == "" ]]; then
    echo "ERROR: Provision a KSQL cluster via the Confluent Cloud UI and add the configuration parameter ksql.endpoint and ksql.basic.auth.user.info into your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi
  ksqlAppId=$(ccloud ksql app list | grep "$ksql_endpoint" | awk '{print $1}')
  if [[ "$ksqlAppId" == "" ]]; then
    echo "ERROR: Confluent Cloud KSQL endpoint $ksql_endpoint is not found. Provision a KSQL cluster via the Confluent Cloud UI and add the configuration parameter ksql.endpoint and ksql.basic.auth.user.info into your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi
  STATUS=$(ccloud ksql app describe $ksqlAppId | grep "Status" | grep UP)
  if [[ "$STATUS" == "" ]]; then
    echo "ERROR: Confluent Cloud KSQL endpoint $ksql_endpoint with id $ksqlAppId is not in UP state. Troubleshoot and try again."
    exit 1
  fi

  check_credentials_ksql "$ksql_endpoint" "$ccloud_config_file" "$credentials" || exit 1

  return 0
}

function check_account_azure() {
  AZBLOB_STORAGE_ACCOUNT=$1

  if [[ "$AZBLOB_STORAGE_ACCOUNT" == "default" ]]; then
    echo "ERROR: Azure Blob storage account name cannot be 'default'. Verify the value of the storage account name (did you create one?) in config/demo.cfg, as specified by the parameter AZBLOB_STORAGE_ACCOUNT, and try again."
    exit 1
  fi

  exists=$(az storage account check-name --name $AZBLOB_STORAGE_ACCOUNT | jq -r .reason)
  if [[ "$exists" != "AlreadyExists" ]]; then
    echo "ERROR: Azure Blob storage account name $AZBLOB_STORAGE_ACCOUNT does not exist. Check the value of STORAGE_PROFILE in config/demo.cfg and try again."
    exit 1
  fi
  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
  if [[ "$AZBLOB_ACCOUNT_KEY" == "" ]]; then
    echo "ERROR: Cannot get the key for Azure Blob storage account name $AZBLOB_STORAGE_ACCOUNT. Check the value of STORAGE_PROFILE in config/demo.cfg, and your key, and try again."
    exit 1
  fi

  return 0
}

function check_credentials_ksql() {
  ksql_endpoint=$1
  ccloud_config_file=$2
  credentials=$3

  response=$(curl ${ksql_endpoint}/info \
             -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
             --silent \
             -u $credentials)
  if [[ "$response" =~ "Unauthorized" ]]; then
    echo "ERROR: Authorization failed to the KSQL cluster. Check your KSQL credentials set in the configuration parameter ksql.basic.auth.user.info in your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi

  echo "Validated credentials to Confluent Cloud KSQL at $ksql_endpoint"
  return 0
}

function create_connector_cloud() {
  file=$1

  echo -e "\nTrying to create connector from $file\n"

  # About the Confluent Cloud CLI command 'ccloud connector create':
  # - Typical usage of this CLI would be 'ccloud connector create --config <filename>'
  # - However, in this demo, the connector's configuration file contains parameters that need to be first substituted
  #   so the CLI command includes eval and heredoc.
  # - The '-vvv' is added for verbose output
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<$file)
EOF
")
  if [[ $? != 0 ]]; then
    echo "ERROR: Exit status was not 0 while creating connector from $file.  Please troubleshoot and try again"
    exit 1
  fi

  return 0
}

function wait_for_connector_up() {
  filename=$1
  maxWait=$2

  connectorName=$(cat $filename | jq -r .name)
  echo "Waiting up to $maxWait seconds for connector $filename ($connectorName) to be RUNNING"
  currWait=0
  while [[ ! $(ccloud connector list | grep $connectorName | awk '{print $5;}') == "RUNNING" ]]; do
    sleep 10
    currWait=$(( currWait+10 ))
    if [[ "$currWait" -gt "$maxWait" ]]; then
      echo -e "\nERROR: Connector $filename ($connectorName) not RUNNING after $maxWait seconds.  Please troubleshoot.\n"
      exit 1
    fi
  done
  echo "Connector $filename ($connectorName) is RUNNING after $currWait seconds"

  return 0

}

check_ccloud_ksql_endpoint_ready() {
  KSQL_ENDPOINT=$1

  ksqlAppId=$(ccloud ksql app list | grep "$KSQL_ENDPOINT" | awk '{print $1}')
  if [[ "$ksqlAppId" == "" ]]; then
    return 1
  fi
  STATUS=$(ccloud ksql app describe $ksqlAppId | grep "Status" | grep UP)
  if [[ "$STATUS" == "" ]]; then
    return 1
  fi

  return 0
}

check_ccloud_cluster_ready() {
  ccloud kafka topic list &>/dev/null
  return $?
}

function ccloud_login(){

  URL=$1
  EMAIL=$2
  PASSWORD=$3

  check_expect

  echo -e "\n# Login"
  OUTPUT=$(
  expect <<END
    log_user 1
    spawn ccloud login --url $URL
    expect "Email: "
    send "$EMAIL\r";
    expect "Password: "
    send "$PASSWORD\r";
    expect "Logged in as "
    set result $expect_out(buffer)
END
  )
  echo "$OUTPUT"
  if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
    echo "Failed to log into your cluster.  Please check all parameters and run again"
  fi

  return 0
}

function ccloud_cli_get_service_account() {
  CLOUD_KEY=$1
  CONFIG_FILE=$2

  if [[ "$CLOUD_KEY" == "" ]]; then
    echo "ERROR: could not parse the broker credentials from $CONFIG_FILE. Verify your credentials and try again."
    exit 1
  fi
  serviceAccount=$(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $3;}')
  if [[ "$serviceAccount" == "" ]]; then
    echo "ERROR: Could not associate key $CLOUD_KEY to a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi
  if ! [[ "$serviceAccount" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: $serviceAccount value is not a valid value for a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi

  echo "$serviceAccount"

  return 0
}

function create_c3_acls() {
  serviceAccount=$1

  echo "Confluent Control Center: creating _confluent-command and ACLs for service account $serviceAccount"
  ccloud kafka topic create _confluent-command --partitions 1

  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic _confluent --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic _confluent --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --topic _confluent --prefix

  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group _confluent --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --consumer-group _confluent --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --consumer-group _confluent --prefix

  return 0
}


function create_replicator_acls() {
  serviceAccount=$1
  topic=$2

  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE-CONFIGS --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation ALTER-CONFIGS --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE --cluster-scope
  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --cluster-scope

  return 0
}

function create_connect_topics_and_acls() {
  serviceAccount=$1

  echo "Connect: creating topics and ACLs for service account $serviceAccount"
  for topic in connect-demo-configs connect-demo-offsets connect-demo-statuses _confluent-monitoring _confluent-command ; do
    ccloud kafka topic create $topic &>/dev/null
    ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $topic --prefix
    ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $topic --prefix
  done
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-cloud

  echo "Connectors: creating topics and ACLs for service account $serviceAccount"
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-replicator
  ccloud kafka acl create --allow --service-account $serviceAccount --operation describe --cluster-scope

  return 0
}

function ccloud_demo_preflight_check() {
  CLOUD_KEY=$1
  CONFIG_FILE=$2
  enable_ksql=$3

  if [ -z "$enable_ksql" ]; then
    enable_ksql=true
  fi

  ccloud_validate_environment_set || exit 1
  ccloud_cli_set_kafka_cluster_use "$CLOUD_KEY" "$CONFIG_FILE" || exit 1
  validate_confluent_cloud_schema_registry "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO" "$SCHEMA_REGISTRY_URL" || exit 1
  if $enable_ksql ; then
    validate_ccloud_ksql "$KSQL_ENDPOINT" "$CONFIG_FILE" "$KSQL_BASIC_AUTH_USER_INFO" || exit 1
  fi
}

function ccloud_validate_environment_set() {
  ccloud environment list | grep '*' &>/dev/null || {
    echo "ERROR: could not determine if environment is set. Run 'ccloud environment list' and set 'ccloud environment use' and try again"
    exit 1
  }

  return 0

}

function ccloud_cli_set_kafka_cluster_use() {
  CLOUD_KEY=$1
  CONFIG_FILE=$2

  if [[ "$CLOUD_KEY" == "" ]]; then
    echo "ERROR: could not parse the broker credentials from $CONFIG_FILE. Verify your credentials and try again."
    exit 1
  fi
  kafkaCluster=$(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $8;}')
  if [[ "$kafkaCluster" == "" ]]; then
    echo "ERROR: Could not associate key $CLOUD_KEY to a Confluent Cloud Kafka cluster. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi
  ccloud kafka cluster use $kafkaCluster
  echo -e "\nAssociated key $CLOUD_KEY to Confluent Cloud Kafka cluster $kafkaCluster:"
  ccloud kafka cluster describe $kafkaCluster

  return 0
}

function cloud_create_demo_stack() {
  enable_ksql=$1

  RANDOM_NUM=$((1 + RANDOM % 1000000))
  #echo "RANDOM_NUM: $RANDOM_NUM"

  SERVICE_NAME="demo-app-$RANDOM_NUM"
  SERVICE_ACCOUNT_ID=$(cloud_create_service_account $SERVICE_NAME)
  echo "Creating Confluent Cloud stack for new service account id $SERVICE_ACCOUNT_ID of name $SERVICE_NAME"

  ENVIRONMENT_NAME="demo-env-$SERVICE_ACCOUNT_ID"
  ENVIRONMENT=$(cloud_create_and_use_environment $ENVIRONMENT_NAME)

  CLUSTER_NAME=demo-kafka-cluster-$SERVICE_ACCOUNT_ID
  CLUSTER_CLOUD="${CLUSTER_CLOUD:-aws}"
  CLUSTER_REGION="${CLUSTER_REGION:-us-west-2}"
  CLUSTER=$(cloud_create_and_use_cluster $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION)
  if [[ "$CLUSTER" == "" ]] ; then
    print_error "Kafka cluster id is empty"
    echo "ERROR: Could not create cluster. Please troubleshoot"
    exit 1
  fi
  BOOTSTRAP_SERVERS=$(ccloud kafka cluster describe $CLUSTER -o json | jq -r ".endpoint" | cut -c 12-)
  CLUSTER_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $CLUSTER)

  MAX_WAIT=720
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud cluster to be ready and for credentials to propagate"
  retry $MAX_WAIT check_ccloud_cluster_ready || exit 1
  # Estimating another 80s wait still sometimes required
  echo "Sleeping an additional 80s to ensure propagation of all metadata"
  sleep 80

  SCHEMA_REGISTRY_GEO="${SCHEMA_REGISTRY_GEO:-us}"
  SCHEMA_REGISTRY=$(cloud_enable_schema_registry $CLUSTER_CLOUD $SCHEMA_REGISTRY_GEO)
  SCHEMA_REGISTRY_ENDPOINT=$(ccloud schema-registry cluster describe -o json | jq -r ".endpoint_url")
  SCHEMA_REGISTRY_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $SCHEMA_REGISTRY)

  if $enable_ksql ; then
    KSQL_NAME="demo-ksql-$SERVICE_ACCOUNT_ID"
    KSQL=$(cloud_create_ksql_app $KSQL_NAME $CLUSTER)
    KSQL_ENDPOINT=$(ccloud ksql app describe $KSQL -o json | jq -r ".endpoint")
    KSQL_CREDS=$(cloud_create_credentials_resource $SERVICE_ACCOUNT_ID $KSQL)
    ccloud ksql app configure-acls $KSQL
  fi

  cloud_create_wildcard_acls $SERVICE_ACCOUNT_ID

  mkdir -p stack-configs
  CLIENT_CONFIG="stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"
  cat <<EOF > $CLIENT_CONFIG
# ------------------------------
# Confluent Cloud connection information for demo purposes only
# Do not use in production
# ------------------------------
# ENVIRONMENT ID: ${ENVIRONMENT}
# SERVICE ACCOUNT ID: ${SERVICE_ACCOUNT_ID}
# KAFKA CLUSTER ID: ${CLUSTER}
# SCHEMA REGISTRY CLUSTER ID: ${SCHEMA_REGISTRY}
EOF
  if $enable_ksql ; then
    cat <<EOF >> $CLIENT_CONFIG
# KSQL ID: ${KSQL}
EOF
  fi
  cat <<EOF >> $CLIENT_CONFIG
# ------------------------------
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="`echo $CLUSTER_CREDS | awk -F: '{print $1}'`" password\="`echo $CLUSTER_CREDS | awk -F: '{print $2}'`";
basic.auth.credentials.source=USER_INFO
schema.registry.url=${SCHEMA_REGISTRY_ENDPOINT}
schema.registry.basic.auth.user.info=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'`:`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
EOF
  if $enable_ksql ; then
    cat <<EOF >> $CLIENT_CONFIG
ksql.endpoint=${KSQL_ENDPOINT}
ksql.basic.auth.user.info=`echo $KSQL_CREDS | awk -F: '{print $1}'`:`echo $KSQL_CREDS | awk -F: '{print $2}'`
EOF
  fi

  echo
  echo "Client configuration file saved to: $CLIENT_CONFIG"

  return 0
}

function cloud_delete_demo_stack() {
  SERVICE_ACCOUNT_ID=$1

  echo "Destroying Confluent Cloud stack associated to service account id $SERVICE_ACCOUNT_ID"

  if [[ $KSQL_ENDPOINT != "" ]]; then
    KSQL=$(ccloud ksql app list | grep demo-ksql-$SERVICE_ACCOUNT_ID | awk '{print $1;}')
    echo "KSQL: $KSQL"
    ccloud ksql app delete $KSQL
  fi

  cloud_delete_demo_stack_acls $SERVICE_ACCOUNT_ID
  ccloud service-account delete $SERVICE_ACCOUNT_ID 

  CLUSTER=$(ccloud kafka cluster list | grep demo-kafka-cluster-$SERVICE_ACCOUNT_ID | tr -d '\*' | awk '{print $1;}')
  echo "CLUSTER: $CLUSTER"
  ccloud kafka cluster delete $CLUSTER

  ENVIRONMENT=$(ccloud environment list | grep demo-env-$SERVICE_ACCOUNT_ID | tr -d '\*' | awk '{print $1;}')
  echo "ENVIRONMENT: $ENVIRONMENT"
  ccloud environment delete $ENVIRONMENT

  CLIENT_CONFIG="stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"
  rm -f $CLIENT_CONFIG

  return 0
}
