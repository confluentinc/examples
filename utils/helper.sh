#!/bin/bash

################################################################
# Source Confluent Platform versions
################################################################
DIR_HELPER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "${DIR_HELPER}/config.env"


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

function validate_version_confluent_cli_v2() {

  if [[ -z $(confluent version | grep "Go") ]]; then
    echo "This example requires the new Confluent CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function get_version_confluent_cli() {
  confluent version | grep "^Version:" | cut -d':' -f2 | cut -d'v' -f2
}

function version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

function validate_version_confluent_cli_for_cp() {

  validate_version_confluent_cli_v2 || exit 1

  VER_MIN="1.11.0"
  VER_MAX="1.22.0"
  CLI_VER=$(get_version_confluent_cli)

  if version_gt $VER_MIN $CLI_VER || version_gt $CLI_VER $VER_MAX ; then
    echo "Confluent CLI version ${CLI_VER} is not compatible with the currently running Confluent Platform version ${CONFLUENT}. Set Confluent CLI version appropriately, see https://docs.confluent.io/platform/current/installation/versions-interoperability.html#confluent-cli for more information."
    exit 1
  fi
}

function check_sqlite3() {
  if [[ $(type sqlite3 2>&1) =~ "not found" ]]; then
    echo "'sqlite3' is not found. Install sqlite3 and try again."
    return 1
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

function version_gt() { 
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
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
    echo "This example requires Docker but it doesn't appear to be running.  Please start Docker and try again."
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

function require_cp_or_exit() {
  command -v confluent >/dev/null 2>&1 || {
    printf "\nconfluent command not found.  Please check your Confluent Platform installation\n"
    exit 1;
  }
}

function check_running_cp() {
  require_cp_or_exit

  expected_version=$1

  actual_version=$( confluent local version 2>&1 | awk -F':' '{print $2;}' | awk '$1 > 0 { print $1}' )
  if [[ $expected_version != $actual_version ]]; then
    printf "\nThis script expects Confluent Platform version $expected_version but the running version is $actual_version.\nTo proceed please either: change the examples repo branch to $actual_version or update the running Confluent Platform to version $expected_version.\n"
    exit 1
  fi

  return 0
}

function check_cp() {
  require_cp_or_exit

  type=$( confluent local version 2>&1 | tail -1 | awk -F: '{print $1;}' | tr '[:lower:]' '[:upper:]')
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
    echo "This example expects MySQL user root password is null. Either reset the MySQL user password or modify the script."
    exit 1
  elif [[ $(echo "show variables;" | mysql -uroot | grep "log_bin\t" 2>&1) =~ "OFF" ]]; then
    echo "The Debezium connector expects MySQL binary logging is enabled. Assuming you installed MySQL on mac with homebrew, modify `/usr/local/etc/my.cnf` and then `brew services restart mysql`"
    exit 1
  fi

  actual_version=$(mysql -V | awk '{print $5;}' | rev | cut -c 2- | rev)
  if [[ $expected_version != $actual_version ]]; then
    echo -e "\nThis example expects MySQL version $expected_version but the running version is $actual_version. Please run the correct version of MySQL to proceed, or comment out the line 'check_mysql' in the start script and run at your own risk.\n"
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

function error_not_compatible_confluent_cli() {
  adoc_file=$1

  echo "******"
  echo "This example is currently runnable only with Docker and not Confluent CLI."
  echo "To run with Docker, follow step-by-step instructions in $adoc_file"
  echo "To run with Confluent CLI on a local Confluent Platform install, this work is in progress and please check back soon!"
  echo "******"

  return 0
}

function get_and_compile_kafka_streams_examples() {

  [[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
  (cd kafka-streams-examples && git fetch && git checkout ${CONFLUENT_RELEASE_TAG_OR_BRANCH} && git pull && echo "Building kafka-streams-examples $CONFLUENT_RELEASE_TAG_OR_BRANCH" && mvn clean package -DskipTests) || {
    echo "ERROR: There seems to be a BUILD FAILURE error with confluentinc/kafka-streams-examples. Please troubleshoot and try again."
    exit 1
  }
  return 0
}

function get_cluster_id_kafka () { 
  KAFKA_CLUSTER_ID=$(curl -s http://localhost:8090/v1/metadata/id | jq -r ".id")
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

function get_service_id_ksqldb () {
  KSQLDB_SERVICE_ID=$(confluent cluster describe --url http://localhost:8088 | grep ksql-cluster | awk '{print $3;}')
  if [[ -z "$KSQLDB_SERVICE_ID" ]]; then
    echo "Failed to get ksqlDB service ID. Please troubleshoot and run again"
    exit 1
  fi
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

host_check_ksqlDBserver_up()
{
  KSQLDB_CLUSTER_ID=$(curl -s http://localhost:8088/info | jq -r ".KsqlServerInfo.ksqlServiceId")
  if [ "$KSQLDB_CLUSTER_ID" == "ksql-cluster" ]; then
    return 0
  fi
  return 1
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

check_rest_proxy_up() {
  containerName=$1

  FOUND=$(docker-compose logs $containerName | grep "Server started, listening for requests")
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

PRETTY_PASS="\e[32m✔ \e[0m"
function print_pass() {
  printf "${PRETTY_PASS}%s\n" "${1}"
}
PRETTY_ERROR="\e[31m✘ \e[0m"
function print_error() {
  printf "${PRETTY_ERROR}%s\n" "${1}"
}
PRETTY_CODE="\e[1;100;37m"
function print_code() {
	printf "${PRETTY_CODE}%s\e[0m\n" "${1}"
}
function print_process_start() {
	printf "⌛ %s\n" "${1}"
}
function print_code_pass() {
  local MESSAGE=""
	local CODE=""
  OPTIND=1
  while getopts ":c:m:" opt; do
    case ${opt} in
			c ) CODE=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
		esac
	done
  shift $((OPTIND-1))
	printf "${PRETTY_PASS}${PRETTY_CODE}%s\e[0m\n" "${CODE}"
	[[ -z "$MESSAGE" ]] || printf "\t$MESSAGE\n"			
}
function print_code_error() {
  local MESSAGE=""
	local CODE=""
  OPTIND=1
  while getopts ":c:m:" opt; do
    case ${opt} in
			c ) CODE=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
		esac
	done
  shift $((OPTIND-1))
	printf "${PRETTY_ERROR}${PRETTY_CODE}%s\e[0m\n" "${CODE}"
	[[ -z "$MESSAGE" ]] || printf "\t$MESSAGE\n"			
}

function exit_with_error()
{
  local USAGE="\nUsage: exit_with_error -c code -n name -m message -l line_number\n"
  local NAME=""
  local MESSAGE=""
  local CODE=$UNSPECIFIED_ERROR
  local LINE=
  OPTIND=1
  while getopts ":n:m:c:l:" opt; do
    case ${opt} in
      n ) NAME=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
      c ) CODE=${OPTARG};;
      l ) LINE=${OPTARG};;
      ? ) printf $USAGE;return 1;;
    esac
  done
  shift $((OPTIND-1))
  print_error "error ${CODE} occurred in ${NAME} at line $LINE"
	printf "\t${MESSAGE}\n"
  exit $CODE
}

function append_once() {
  if ! grep -q ${1} ${2}; then
    echo ${1} >> ${2}
  fi
}

function check_ksqlDB_host_running()
{
  if [[ $(curl -s http://ksqldb-server:8088/info) != *RUNNING* ]]; then
    return 1
  fi
  return 0
}

function check_schema_registry_topics_exists()
{
  SR_TOPICS=$(curl -s http://schema-registry:8081/subjects)
  arr=("$@")
  for i in "${arr[@]}";
    do
      if [ $(echo "$SR_TOPICS" | grep -v "$i") ]; then
        return 1
      fi
    done
  return 0
}