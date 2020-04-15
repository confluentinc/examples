#!/bin/bash

################################################################
# Source Confluent Platform versions
################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. "$DIR/config.env"


################################################################
# Library of functions
################################################################

function check_env() {
  if [[ -z "$CONFLUENT_HOME" ]]; then
    echo "\$CONFLUENT_HOME is not defined. Run 'export CONFLUENT_HOME=/path/to/confluentplatform' and try again"
    exit 1
  fi

  if [[ $(type confluent 2>&1) =~ "not found" ]]; then
    echo "'confluent' is not found. Download Confluent Platform (https://www.confluent.io/download) to get the new Confluent CLI and try again"
    exit 1
  fi

  if [[ $(type kafka-server-start 2>&1) =~ "not found" ]]; then
    echo "Cannot find 'kafka-server-start'. Please add \$CONFLUENT_HOME/bin to \$PATH (e.g. 'export PATH=\${CONFLUENT_HOME}/bin:\${PATH}') and try again."
    exit 1
  fi

  return 0
}

function check_python() {
  if [[ $(type python 2>&1) =~ "not found" ]]; then
    echo "'python' is not found. Install python and try again."
    return 1
  fi

  return 0
}

function check_confluent_binary() {
  if [[ $(type confluent 2>&1) =~ "not found" ]]; then
    echo "'confluent' is not found. Install Confluent Platform if you want to use Confluent CLI."
    return 1
  fi

  return 0
}

function check_ccloud_binary() {
  if [[ $(type ccloud 2>&1) =~ "not found" ]]; then
    echo "'ccloud' is not found. Install Confluent Cloud CLI (https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli) and try again"
    exit 1
  fi
}

function check_ccloud() {

  check_ccloud_binary || exit 1

  if [[ ! -e "$HOME/.ccloud/config" ]]; then
    echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
    exit 1
  fi

  return 0
}

function check_ccloud_v1() {
  expected_version="0.2.0"

  check_ccloud || exit 1

  actual_version=$(ccloud version | grep -i "version" | awk '{print $3;}')
  if ! [[ $actual_version =~ $expected_version ]]; then
    echo "This demo requires Confluent Cloud CLI version $expected_version but the running version is '$actual_version'. Please update your version and try again."
    exit 1
  fi

  return 0
}

function check_ccloud_v2() {

  check_ccloud || exit 1

  if [[ -z $(ccloud version | grep "Go") ]]; then
    echo "This demo requires the new Confluent Cloud CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function check_ccloud_logged_in() {
  check_ccloud_v2 || exit 1

  if [[ "$(ccloud kafka cluster list 2>&1)" == "Error: You must log in to run that command." ]]; then
    echo "ERROR: Log into Confluent Cloud with the command 'ccloud login' before running the demo."
    exit 1
  fi

  return 0
}

function version_gt() { 
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
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

function check_timeout() {
  if [[ $(type timeout 2>&1) =~ "not found" ]]; then
    echo "'timeout' is not found. Install 'timeout' and try again"
    exit 1
  fi

  return 0
}

function check_docker() {
  if ! docker ps -q &>/dev/null; then
    echo "This demo requires Docker but it doesn't appear to be running.  Please start Docker and try again."
    exit 1
  fi

  return 0
}

function check_jq() {
  if [[ $(type jq 2>&1) =~ "not found" ]]; then
    echo "'jq' is not found. Install 'jq' and try again"
    exit 1
  fi

  return 0
}

function check_expect() {
  if [[ $(type expect 2>&1) =~ "not found" ]]; then
    echo "'expect' is not found. Install 'expect' and try again"
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

function require_cp_or_exit() {
  command -v confluent >/dev/null 2>&1 || {
    printf "\nconfluent command not found.  Please check your Confluent Platform installation\n"
    exit 1;
  }
}

function check_running_cp() {
  require_cp_or_exit

  expected_version=$1

  actual_version=$( confluent local version 2>/dev/null | awk -F':' '{print $2;}' | awk '$1 > 0 { print substr($1,1,3)}' )
  if [[ $expected_version != $actual_version ]]; then
    printf "\nThis script expects Confluent Platform version $expected_version but the running version is $actual_version.\nTo proceed please either: change the examples repo branch to $actual_version or update the running Confluent Platform to version $expected_version.\n"
    exit 1
  fi

  return 0
}

function check_cp() {
  require_cp_or_exit

  type=$( confluent local version 2>/dev/null | tail -1 | awk -F: '{print $1;}' | tr '[:lower:]' '[:upper:]')
  case $type in
    *PLATFORM*)
      return 0 ;; 
    *COMMUNITY*)
      return 1 ;;
    *)
      echo -e "\nCannot determine if Confluent Platform or Confluent Community Software from 'confluent local version'. Assuming Confluent Community Software\n"
      return 1 ;;
  esac

  return 1
}

function check_running_elasticsearch() {
  check_curl || exit 1
  check_jq   || exit 1

  expected_version=$1
  port=${2:-9200}

  es_status=$(curl --silent http://localhost:$port/?pretty) || {
    printf "\nTo showcase a sink connector, this script requires Elasticsearch to be listening on port $port. Please reconfigure and restart Elasticsearch and run again.\n"
    exit 1
  }
  
  actual_version=$(echo $es_status | jq .version.number -r)
  if [[ $expected_version != $actual_version ]]; then
    printf "\nTo showcase a sink connector, this script requires Elasticsearch version $expected_version but the running version is $actual_version. Please run the correct version of Elasticsearch to proceed.\n"
    exit 1
  fi

  return 0
}

function check_running_grafana() {
  check_curl || exit 1
  check_jq   || exit 1

  expected_version=$1
  port=${2:-3000}

  grafana_status=$(curl --silent http://localhost:$port/api/health) || {
   printf "\nTo showcase a sink connector, this script requires Grafana to be listening on port $port. Please reconfigure and restart Grafana and run again.\n"
   exit 1
  }

  actual_version=$(echo $grafana_status | jq .version -r)
  if [[ $expected_version != $actual_version ]]; then
    printf "\nTo showcase a sink connector, this script requires Grafana version $expected_version but the running version is $actual_version. Please run the correct version of Grafana to proceed.\n"
    exit 1
  fi

  return 0
}

function check_running_kibana() {
  check_curl || exit 1

  port=${1:-5601}
  kibana_status=$(curl --silent http://localhost:$port/api/status) || {
    printf "\nTo showcase a sink connector, this script requires Kibana to be listening on port $port. Please reconfigure and restart Kibana and run again.\n"
    exit 1
  }

  return 0
}

function check_mvn() {
  if [[ $(type mvn 2>&1) =~ "not found" ]]; then
    echo "'mvn' is not found. Install Maven and try again"
    exit 1
  fi

  return 0
}

function check_jot() {
  if [[ $(type jot 2>&1) =~ "not found" ]]; then
    echo "'jot' is not found. Install jot, for random number generation, and try again"
    exit 1
  fi

  return 0
}

function check_netstat() {
  if [[ $(type netstat 2>&1) =~ "not found" ]]; then
    echo "'netstat' is not found. Install netstat, typically provided by the net-tools package, and try again"
    exit 1
  fi

  return 0
}

function check_mysql() {
  expected_version=$1

  if [[ $(type mysql 2>&1) =~ "not found" ]]; then
    echo "'mysql' is not found. Install MySQL and try again"
    exit 1
  elif [[ $(echo "exit" | mysql demo -uroot 2>&1) =~ "Access denied" ]]; then
    echo "This demo expects MySQL user root password is null. Either reset the MySQL user password or modify the script."
    exit 1
  elif [[ $(echo "show variables;" | mysql -uroot | grep "log_bin\t" 2>&1) =~ "OFF" ]]; then
    echo "The Debezium connector expects MySQL binary logging is enabled. Assuming you installed MySQL on mac with homebrew, modify `/usr/local/etc/my.cnf` and then `brew services restart mysql`"
    exit 1
  fi

  actual_version=$(mysql -V | awk '{print $5;}' | rev | cut -c 2- | rev)
  if [[ $expected_version != $actual_version ]]; then
    echo -e "\nThis demo expects MySQL version $expected_version but the running version is $actual_version. Please run the correct version of MySQL to proceed, or comment out the line 'check_mysql' in the start script and run at your own risk.\n"
    exit 1
  fi

  return 0
}

function check_curl() {
  if [[ $(type curl 2>&1) =~ "not found" ]]; then
    echo "'curl' is not found.  Install curl to continue"
    exit 1
  fi
  return 0
}

function prep_sqltable_locations() {
  TABLE="locations"
  TABLE_PATH=/usr/local/lib/table.$TABLE
  cp ../utils/table.$TABLE $TABLE_PATH

  DB=/usr/local/lib/retail.db
  echo "DROP TABLE IF EXISTS $TABLE;" | sqlite3 $DB
  echo "CREATE TABLE $TABLE(id INTEGER KEY NOT NULL, name VARCHAR(255), sale INTEGER);" | sqlite3 $DB
  echo ".import $TABLE_PATH $TABLE" | sqlite3 $DB
  #echo "pragma table_info($TABLE);" | sqlite3 $DB
  #echo "select * from $TABLE;" | sqlite3 $DB

  # View contents of file
  #echo -e "\n======= Contents of $TABLE_PATH ======="
  #cat $TABLE_PATH

  return 0
}

function prep_sqltable_customers() {
  TABLE="customers"
  TABLE_PATH=/usr/local/lib/table.$TABLE
  cp ../utils/table.$TABLE $TABLE_PATH

  DB=/usr/local/lib/microservices.db
  echo "DROP TABLE IF EXISTS $TABLE;" | sqlite3 $DB
  echo "CREATE TABLE $TABLE(id INTEGER KEY NOT NULL, firstName VARCHAR(255), lastName VARCHAR(255), email VARCHAR(255), address VARCHAR(255), level VARCHAR(255));" | sqlite3 $DB
  echo ".import $TABLE_PATH $TABLE" | sqlite3 $DB
  #echo "pragma table_info($TABLE);" | sqlite3 $DB
  #echo "select * from $TABLE;" | sqlite3 $DB

  # View contents of file
  #echo -e "\n======= Contents of $TABLE_PATH ======="
  #cat $TABLE_PATH

  return 0
}

function error_not_compatible_confluent_cli() {
  adoc_file=$1

  echo "******"
  echo "This demo is currently runnable only with Docker and not Confluent CLI."
  echo "To run with Docker, follow step-by-step instructions in $adoc_file"
  echo "To run with Confluent CLI on a local Confluent Platform install, this work is in progress and please check back soon!"
  echo "******"

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

  curl --silent -u $auth $sr_endpoint || {
    echo "ERROR: Could not validate credentials to Confluent Cloud Schema Registry. Please troubleshoot"
    exit 1
  }
  return 0
}

function get_and_compile_kafka_streams_examples() {

  [[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
  (cd kafka-streams-examples && git fetch && git checkout ${CONFLUENT_RELEASE_TAG_OR_BRANCH} && git pull && mvn package -DskipTests) || {
    echo "ERROR: There seems to be a BUILD FAILURE error with confluentinc/kafka-streams-examples. Please troubleshoot and try again."
    exit 1
  }
  return 0
}

function get_cluster_id_kafka () { 
  KAFKA_CLUSTER_ID=$(zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep version | jq -r .id)
  if [[ -z "$KAFKA_CLUSTER_ID" ]]; then
    echo "Failed to get Kafka cluster ID. Please troubleshoot and run again"
    exit 1
  fi
  return 0
}

function get_cluster_id_schema_registry () {
  SCHEMA_REGISTRY_CLUSTER_ID=$(confluent cluster describe --url http://localhost:8081 | grep schema-registry-cluster | awk '{print $3;}')
  if [[ -z "$SCHEMA_REGISTRY_CLUSTER_ID" ]]; then
    echo "Failed to get Schema Registry cluster ID. Please troubleshoot and run again"
    exit 1
  fi
  return 0
}

function get_cluster_id_connect () {
  CONNECT_CLUSTER_ID=$(confluent cluster describe --url http://localhost:8083 | grep connect-cluster | awk '{print $3;}')
  if [[ -z "$CONNECT_CLUSTER_ID" ]]; then
    echo "Failed to get Connect cluster ID. Please troubleshoot and run again"
    exit 1
  fi
  return 0
}

function get_service_id_ksql () {
  KSQL_SERVICE_ID=$(confluent cluster describe --url http://localhost:8088 | grep ksql-cluster | awk '{print $3;}')
  if [[ -z "$KSQL_SERVICE_ID" ]]; then
    echo "Failed to get KSQL service ID. Please troubleshoot and run again"
    exit 1
  fi
  return 0
}

function check_ccloud_config() {
  expected_configfile=$1

  if [[ ! -f "$expected_configfile" ]]; then
    echo "Confluent Cloud configuration file does not exist at $expected_configfile. Please create the configuration file with properties set to your Confluent Cloud cluster and try again."
    exit 1
  elif ! [[ $(grep "^\s*bootstrap.server" $expected_configfile) ]]; then
    echo "Missing 'bootstrap.server' in $expected_configfile. Please modify the configuration file with properties set to your Confluent Cloud cluster and try again."
    exit 1
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
  echo $response
  if [[ "$response" =~ "Unauthorized" ]]; then
    echo "ERROR: Authorization failed to the KSQL cluster. Check your KSQL credentials set in the configuration parameter ksql.basic.auth.user.info in your Confluent Cloud configuration file at $credentials and try again."
    exit 1
  fi

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

retry() {
    local -r -i max_wait="$1"; shift
    local -r cmd="$@"

    local -i sleep_interval=5
    local -i curr_wait=0

    until $cmd
    do
        if (( curr_wait >= max_wait ))
        then
            echo "ERROR: Failed after $curr_wait seconds. Please troubleshoot and run again."
            return 1
        else
            printf "."
            curr_wait=$((curr_wait+sleep_interval))
            sleep $sleep_interval
        fi
    done
    printf "\n"
}

check_connect_up_logFile() {
  logFile=$1

  FOUND=$(grep "Herder started" $logFile)
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

check_connect_up() {
  containerName=$1

  FOUND=$(docker-compose logs $containerName | grep "Herder started")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

check_control_center_up() {
  containerName=$1

  FOUND=$(docker-compose logs $containerName | grep "Started NetworkTrafficServerConnector")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

check_topic_exists() {
  containerName=$1
  brokerConn=$2
  topic=$3

  docker-compose exec $containerName kafka-topics --bootstrap-server $brokerConn --describe --topic $topic >/dev/null
  return $?
}

check_connector_status_running() {
  port=$1
  connectorName=$2

  STATE=$(curl --silent "http://localhost:$port/connectors/$connectorName/status" | jq -r '.connector.state')
  if [[ "$STATE" != "RUNNING" ]]; then
    return 1
  fi
  return 0
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

function create_connect_topics_and_acls() {
  serviceAccount=$1

  echo "Creating topics and ACLs for connect for service account $serviceAccount"
  for topic in connect-offsets connect-statuses connect-configs _confluent-monitoring ; do
    ccloud kafka topic create $topic &>/dev/null
    ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $topic --prefix
    ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $topic --prefix
  done
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-cloud

  echo "Creating topics and ACLs for connectors for service account $serviceAccount"
  for topic in __consumer_timestamps ; do
    ccloud kafka topic create $topic &>/dev/null
    ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $topic --prefix
    ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $topic --prefix
  done
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-replicator

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
  echo -e "\nAssociated key $CLOUD_KEY to Confluent Cloud Kafka cluster $kafkaCluster:\n"
  ccloud kafka cluster describe $kafkaCluster
  
  return 0
}


# Converts properties file of key/value pairs into prefixed environment variables for Docker
# Naming convention: convert properties file into env vars as uppercase and replace '.' with '_'
# Inverse of env_to_props: https://github.com/confluentinc/confluent-docker-utils/blob/master/confluent/docker_utils/dub.py
function props_to_env() {
  properties_file=$1
  prop_prefix=$2

  env_file="${properties_file}.env"
  rm -f $env_file
  cat $properties_file | while IFS='=' read key value; do
    if [[ $key != "" && ${key:0:1} != "#" ]] ; then
      newkey=$(echo "${prop_prefix}_${key}" | tr '[:lower:]' '[:upper:]' | tr '.' '_')
      if [[ "${newkey}" =~ "SASL_JAAS_CONFIG" ]]; then
        value="\'${value}\'"
      fi
      echo "$newkey=$value" >> $env_file
      echo "$newkey=$value"
    fi
  done
}
