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