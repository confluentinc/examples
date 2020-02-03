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
    echo "'confluent' is not found. Since CP 5.3, the Confluent CLI is a separate download. Install the new Confluent CLI (https://docs.confluent.io/current/cli/installing.html) and try again"
    exit 1
  fi

  if [[ $(type kafka-server-start 2>&1) =~ "not found" ]]; then
    echo "Cannot find 'kafka-server-start'. Please add \$CONFLUENT_HOME/bin to \$PATH (e.g. 'export PATH=\${CONFLUENT_HOME}/bin:\${PATH}') and try again."
    exit 1
  fi

  return 0
}

function check_ccloud_binary() {
  if [[ $(type ccloud 2>&1) =~ "not found" ]]; then
    echo "'ccloud' is not found. Install Confluent Cloud CLI (https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli) and try again"
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

function check_gcp_creds() {
  if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]] && [[ ! -f $HOME/.config/gcloud/application_default_credentials.json ]]; then
    echo "To run this demo to GCS, either set the env parameter 'GOOGLE_APPLICATION_CREDENTIALS' or run 'gcloud auth application-default login', and then try again."
    exit 1
  fi
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


function validate_confluent_cloud_schema_registry() {
  auth=$1
  sr_endpoint=$2

  curl --silent -u $auth $sr_endpoint
  if [[ "$?" -ne 0 ]]; then
    echo "ERROR: Could not validate credentials to Confluent Cloud Schema Registry. Please troubleshoot"
    exit 1
  fi
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
