#!/bin/bash

function check_env() {
  if [[ -z "$CONFLUENT_HOME" ]]; then
    echo "\$CONFLUENT_HOME is not defined. Run 'export CONFLUENT_HOME=/path/to/confluentplatform' and try again"
    exit 1
  fi

  if [[ $(type confluent 2>&1) =~ "not found" ]]; then
    echo "'confluent' is not found. Run 'export PATH=\${CONFLUENT_HOME}/bin:\${PATH}' and try again"
    exit 1
  fi

  return 0
}

function check_ccloud() {
  if [[ $(type ccloud 2>&1) =~ "not found" ]]; then
    echo "'ccloud' is not found. Install Confluent Cloud CLI (https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli) and try again"
    exit 1
  fi

  if [[ ! -e "$HOME/.ccloud/config" ]]; then
    echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
    exit 1
  fi

  return 0
}

function check_running_cp() {
  expected_version=$1

  actual_version=$( confluent version | tail -1 | awk -F':' '{print $2;}' | awk '$1 > 0 { print substr($1,1,3)}' )
  if [[ $expected_version != $actual_version ]]; then
    echo -e "\nThis script expects Confluent Platform version $expected_version but the running version is $actual_version.\nTo proceed please either: change the examples repo branch to $actual_version or update the running Confluent Platform to version $expected_version.\n"
    exit 1
  fi

  return 0
}

function is_ce() {
  type=$( confluent version | tail -1 | awk -F: '{print $1;}' )
  if [[ "$type" == "Confluent Platform" ]]; then
    return 0
  elif [[ "$type" == "Confluent Community software" ]]; then
    return 1
  else
    echo -e "\nCannot determine if Confluent Platform or Confluent Community software from `confluent version`. Assuming Confluent Community\n"
    return 1
  fi
}

function check_running_elasticsearch() {
  expected_version=$1

  if [[ ! $(jps | grep Elasticsearch) ]]; then
    echo -e "\nTo showcase a sink connector, this script requires Elasticsearch version $expected_version to be running. Please start Elasticsearch and run again, or comment out '${FUNCNAME[0]}' in the 'start.sh' script.\n"
    exit 1
  else
    curl --silent --output /dev/null 'http://localhost:9200/?pretty'
    status=$?
    if [[ ${status} -ne 0 ]]; then
      echo -e "\nTo showcase a sink connector, this script requires Elasticsearch to be listening on port 9200. Please reconfigure and restart Elasticsearch and run again.\n"
      exit 1
    else
      actual_version=$(curl --silent 'http://localhost:9200/?pretty' | jq .version.number -r)
      if [[ $expected_version != $actual_version ]]; then
        echo -e "\nTo showcase a sink connector, this script requires Elasticsearch version $expected_version but the running version is $actual_version. Please run the correct version of Elasticsearch to proceed.\n"
        exit 1
      fi
    fi
  fi

  return 0
}

function check_running_grafana() {
  expected_version=$1

  if [[ $(ps -ef | grep grafana-server | grep -v grep ) == "" ]]; then
    echo -e "\nTo showcase a sink connector, this script requires Grafana to be running. Please start Grafana and run again, or comment out '${FUNCNAME[0]}' in the 'start.sh' script.\n"
    exit 1
  else
    curl --silent --output /dev/null 'http://localhost:3000/?pretty'
    status=$?
    if [[ ${status} -ne 0 ]]; then
      echo -e "\nTo showcase a sink connector, this script requires Grafana to be listening on port 3000. Please reconfigure and restart Grafana and run again.\n"
      exit 1
    else
      actual_version=$(grafana-server -v | awk '{print $2;}')
      if [[ $expected_version != $actual_version ]]; then
        echo -e "\nTo showcase a sink connector, this script requires Grafana version $expected_version but the running version is $actual_version. Please run the correct version of Grafana to proceed.\n"
      exit 1
      fi
    fi
  fi

  return 0
}

function check_running_kibana() {
  if [[ $(ps -ef | grep kibana | grep -v grep ) == "" ]]; then
    echo -e "\nTo showcase a sink connector, this script requires Kibana to be running. Please start Kibana and run again, or comment out '${FUNCNAME[0]}' in the 'start.sh' script.\n"
    exit 1
  else
    curl --silent --output /dev/null 'http://localhost:5601/?pretty'
    status=$?
    if [[ ${status} -ne 0 ]]; then
      echo -e "\nTo showcase a sink connector, this script requires Kibana to be listening on port 5601. Please reconfigure and restart Kibana and run again.\n"
      exit 1
    fi
  fi

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
  echo "CREATE TABLE $TABLE(id INTEGER KEY NOT NULL, firstName VARCHAR(255), lastName VARCHAR(255), email VARCHAR(255), address VARCHAR(255));" | sqlite3 $DB
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
