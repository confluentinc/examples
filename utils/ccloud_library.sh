#!/bin/bash

################################################################
# ccloud_library.sh
# --------------------------------------------------------------
# This library of functions automates common tasks with Confluent Cloud https://www.confluent.io/confluent-cloud/
#
# Example usage in https://github.com/confluentinc/examples
#
# Get the library:
#
#   curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
#
# Use the library from your script:
#
#   source ./ccloud_library.sh
#
# Support:
#
#   1. Community support via https://github.com/confluentinc/examples/issues
#   2. There are no guarantees for backwards compatibility
#   3. PRs welcome ;) 
################################################################


# --------------------------------------------------------------
# Initialize
# --------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

CLI_MIN_VERSION=${CLI_MIN_VERSION:-3.0.0}

# --------------------------------------------------------------
# Library
# --------------------------------------------------------------

function ccloud::prompt_continue_ccloud_demo() {
  echo
  echo "--------------------------------------------------------------------------------------------"
  echo "This example runs on Confluent Cloud, sign up here:"
  echo
  echo "         https://www.confluent.io/confluent-cloud/tryfree/"
  echo
  echo "The example uses real Confluent Cloud resources that may be billable, including connectors"
  echo "and ksqlDB applications that may have hourly charges. The end of this script shows a command"
  echo "you can run to destroy all the cloud resources, and you should verify they are destroyed."
  echo
  echo "You may be billed for the Confluent Cloud resources until you destroy them."
  echo "--------------------------------------------------------------------------------------------"
  echo

  read -p "Do you still want to run this script? [y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      exit 1
  fi

  return 0
}
function ccloud::validate_expect_installed() {
  if [[ $(type expect 2>&1) =~ "not found" ]]; then
    echo "'expect' is not found. Install 'expect' and try again"
    exit 1
  fi

  return 0
}
function ccloud::validate_cli_installed() {
  if [[ $(type confluent 2>&1) =~ "not found" ]]; then
    echo "'confluent' is not found. Install the Confluent CLI (https://docs.confluent.io/confluent-cli/current/install.html) and try again."
    exit 1
  fi
}

function ccloud::validate_cli_v2() {
  ccloud::validate_cli_installed || exit 1

  if [[ -z $(confluent version 2>&1 | grep "Go") ]]; then
    echo "This example requires the new Confluent CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function ccloud::validate_logged_in_cli() {
  ccloud::validate_cli_v2 || exit 1

  if [[ "$(confluent kafka cluster list 2>&1)" =~ "confluent login" ]]; then
    echo
    echo "ERROR: Not logged into Confluent Cloud."
    echo "Log in with the command 'confluent login --save' before running the example. The '--save' argument saves your Confluent Cloud user login credentials or refresh token (in the case of SSO) to the local netrc file."
    exit 1
  fi

  return 0
}

function ccloud::get_version_cli() {
  confluent version | grep "^Version:" | cut -d':' -f2 | cut -d'v' -f2
}

function ccloud::validate_version_cli() {
  ccloud::validate_cli_installed || exit 1

  CLI_VERSION=$(ccloud::get_version_cli)

  if ccloud::version_gt $CLI_MIN_VERSION $CLI_VERSION; then
    echo "confluent version ${CLI_MIN_VERSION} or greater is required. Current version: ${CLI_VERSION}"
    echo "To update, follow: https://docs.confluent.io/confluent-cli/current/migrate.html"
    exit 1
  fi
}

function ccloud::validate_psql_installed() {
  if [[ $(type psql 2>&1) =~ "not found" ]]; then
    echo "psql is not found. Install psql and try again"
    exit 1
  fi

  return 0
}

function ccloud::validate_aws_cli_installed() {
  if [[ $(type aws 2>&1) =~ "not found" ]]; then
    echo "AWS CLI is not found. Install AWS CLI and try again"
    exit 1
  fi

  return 0
}

function ccloud::get_version_aws_cli() {
  version_major=$(aws --version 2>&1 | awk -F/ '{print $2;}' | head -c 1)
  if [[ "$version_major" -eq 2 ]]; then
    echo "2"
  else
    echo "1"
  fi
  return 0
}

function ccloud::validate_gsutil_installed() {
  if [[ $(type gsutil 2>&1) =~ "not found" ]]; then
    echo "Google Cloud gsutil is not found. Install Google Cloud gsutil and try again"
    exit 1
  fi

  return 0
}

function ccloud::validate_az_installed() {
  if [[ $(type az 2>&1) =~ "not found" ]]; then
    echo "Azure CLI is not found. Install Azure CLI and try again"
    exit 1
  fi

  return 0
}

function ccloud::validate_cloud_source() {
  config=$1

  source $config

  if [[ "$DATA_SOURCE" == "kinesis" ]]; then
    ccloud::validate_aws_cli_installed || exit 1
    if [[ -z "$KINESIS_REGION" || -z "$AWS_PROFILE" ]]; then
      echo "ERROR: DATA_SOURCE=kinesis, but KINESIS_REGION or AWS_PROFILE is not set.  Please set these parameters in config/demo.cfg and try again."
      exit 1
    fi
    aws kinesis list-streams --profile $AWS_PROFILE --region $KINESIS_REGION > /dev/null \
      || { echo "Could not run 'aws kinesis list-streams'.  Check credentials and run again." ; exit 1; }
  elif [[ "$DATA_SOURCE" == "rds" ]]; then
    ccloud::validate_aws_cli_installed || exit 1
    if [[ -z "$RDS_REGION" || -z "$AWS_PROFILE" ]]; then
      echo "ERROR: DATA_SOURCE=rds, but RDS_REGION or AWS_PROFILE is not set.  Please set these parameters in config/demo.cfg and try again."
      exit 1
    fi
    aws rds describe-db-instances --profile $AWS_PROFILE --region $RDS_REGION > /dev/null \
      || { echo "Could not run 'aws rds describe-db-instances'.  Check credentials and run again." ; exit 1; }
  else
    echo "Cloud source $cloudsource is not valid.  Must be one of [kinesis|rds]."
    exit 1
  fi

  return 0
}

function ccloud::validate_cloud_storage() {
  config=$1

  source $config
  storage=$DESTINATION_STORAGE

  if [[ "$storage" == "s3" ]]; then
    ccloud::validate_aws_cli_installed || exit 1
    ccloud::validate_credentials_s3 $S3_PROFILE $S3_BUCKET || exit 1
    aws s3api list-buckets --profile $S3_PROFILE --region $STORAGE_REGION > /dev/null \
      || { echo "Could not run 'aws s3api list-buckets'.  Check credentials and run again." ; exit 1; }
  elif [[ "$storage" == "gcs" ]]; then
    ccloud::validate_gsutil_installed || exit 1
    ccloud::validate_credentials_gcp $GCS_CREDENTIALS_FILE $GCS_BUCKET || exit 1
  elif [[ "$storage" == "az" ]]; then
    ccloud::validate_az_installed || exit 1
    ccloud::validate_credentials_az $AZBLOB_STORAGE_ACCOUNT $AZBLOB_CONTAINER || exit 1
  else
    echo "Storage destination $storage is not valid.  Must be one of [s3|gcs|az]."
    exit 1
  fi

  return 0
}

function ccloud::validate_credentials_gcp() {
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

function ccloud::validate_credentials_az() {
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

function ccloud::validate_credentials_s3() {
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

function ccloud::validate_schema_registry_up() {
  auth=$1
  sr_endpoint=$2

  curl --silent -u $auth $sr_endpoint > /dev/null || {
    echo "ERROR: Could not validate credentials to Confluent Cloud Schema Registry. Please troubleshoot"
    exit 1
  }

  echo "Validated credentials to Confluent Cloud Schema Registry at $sr_endpoint"
  return 0
}

function ccloud::get_environment_id_from_service_id() {
  SERVICE_ACCOUNT_ID=$1

  ENVIRONMENT_NAME_PREFIX=${ENVIRONMENT_NAME_PREFIX:-"ccloud-stack-$SERVICE_ACCOUNT_ID"}
  local environment_id=$(confluent environment list -o json | jq -r 'map(select(.name | startswith("'"$ENVIRONMENT_NAME_PREFIX"'"))) | .[].id')

  echo $environment_id

  return 0
}


function ccloud::create_and_use_environment() {
  ENVIRONMENT_NAME=$1

  OUTPUT=$(confluent environment create $ENVIRONMENT_NAME -o json)
  (($? != 0)) && { echo "ERROR: Failed to create environment $ENVIRONMENT_NAME. Please troubleshoot and run again"; exit 1; }
  ENVIRONMENT=$(echo "$OUTPUT" | jq -r ".id")
  confluent environment use $ENVIRONMENT &>/dev/null

  echo $ENVIRONMENT

  return 0
}

function ccloud::find_cluster() {
  CLUSTER_NAME=$1
  CLUSTER_CLOUD=$2
  CLUSTER_REGION=$3

  local FOUND_CLUSTER=$(confluent kafka cluster list -o json | jq -c -r '.[] | select((.name == "'"$CLUSTER_NAME"'") and (.provider == "'"$CLUSTER_CLOUD"'") and (.region == "'"$CLUSTER_REGION"'"))')
  [[ ! -z "$FOUND_CLUSTER" ]] && {
      echo "$FOUND_CLUSTER" | jq -r .id
      return 0 
    } || {
      return 1
    }
}

function ccloud::create_and_use_cluster() {
  CLUSTER_NAME=$1
  CLUSTER_CLOUD=$2
  CLUSTER_REGION=$3

  OUTPUT=$(confluent kafka cluster create "$CLUSTER_NAME" --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION --output json 2>&1)
  (($? != 0)) && { echo "$OUTPUT"; exit 1; }
  CLUSTER=$(echo "$OUTPUT" | jq -r .id)
  confluent kafka cluster use $CLUSTER 2>/dev/null
  echo $CLUSTER

  return 0
}

function ccloud::maybe_create_and_use_cluster() {
  CLUSTER_NAME=$1
  CLUSTER_CLOUD=$2
  CLUSTER_REGION=$3
  CLUSTER_ID=$(ccloud::find_cluster $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION)
  if [ $? -eq 0 ]
  then
    confluent kafka cluster use $CLUSTER_ID
    echo $CLUSTER_ID
  else
    OUTPUT=$(ccloud::create_and_use_cluster "$CLUSTER_NAME" "$CLUSTER_CLOUD" "$CLUSTER_REGION")
    (($? != 0)) && { echo "$OUTPUT"; exit 1; }
    echo "$OUTPUT"
  fi

  return 0
}

function ccloud::create_service_account() {
  SERVICE_NAME=$1

  CCLOUD_EMAIL=$(confluent prompt -f '%u')
  OUTPUT=$(confluent iam service-account create $SERVICE_NAME --description "SA for $EXAMPLE run by $CCLOUD_EMAIL"  -o json)
  SERVICE_ACCOUNT_ID=$(echo "$OUTPUT" | jq -r ".id")

  echo $SERVICE_ACCOUNT_ID

  return 0
}

function ccloud:get_service_account_from_current_cluster_name() {
  SERVICE_ACCOUNT_ID=$(confluent kafka cluster describe -o json | jq -r '.name' | awk -F'-' '{print $4 "-" $5;}')

  echo $SERVICE_ACCOUNT_ID

  return 0
}

function ccloud::enable_schema_registry() {
  SCHEMA_REGISTRY_CLOUD=$1
  SCHEMA_REGISTRY_GEO=$2

  OUTPUT=$(confluent schema-registry cluster enable --cloud $SCHEMA_REGISTRY_CLOUD --geo $SCHEMA_REGISTRY_GEO -o json)
  SCHEMA_REGISTRY=$(echo "$OUTPUT" | jq -r ".id")

  echo $SCHEMA_REGISTRY

  return 0
}

function ccloud::find_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2
  local FOUND_CRED=$(confluent api-key list -o json | jq -c -r 'map(select((.resource_id == "'"$RESOURCE"'") and (.owner_resource_id == "'"$SERVICE_ACCOUNT_ID"'")))')
  local FOUND_COUNT=$(echo "$FOUND_CRED" | jq 'length')
  [[ $FOUND_COUNT -ne 0 ]] && {
      echo "$FOUND_CRED" | jq -r '.[0].key'
      return 0 
    } || {
      return 1
    }
}
function ccloud::create_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2

  OUTPUT=$(confluent api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json)
  API_KEY_SA=$(echo "$OUTPUT" | jq -r ".api_key")
  API_SECRET_SA=$(echo "$OUTPUT" | jq -r ".api_secret")

  echo "${API_KEY_SA}:${API_SECRET_SA}"

  return 0
}
#####################################################################
# The return from this function will be a colon ':' delimited
#   list, if the api-key is created the second element of the
#   list will be the secret.  If the api-key is being reused
#   the second element of the list will be empty
#####################################################################
function ccloud::maybe_create_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2
  
  local KEY=$(ccloud::find_credentials_resource $SERVICE_ACCOUNT_ID $RESOURCE)
  [[ -z $KEY ]] && {
    ccloud::create_credentials_resource $SERVICE_ACCOUNT_ID $RESOURCE || exit 1
  } || {
    echo "$KEY:"; # the secret cannot be retrieved from a found key, caller needs to handle this
    return 0
  }
}

function ccloud::find_ksqldb_app() {
  KSQLDB_NAME=$1
  CLUSTER=$2

  local FOUND_APP=$(confluent ksql cluster list -o json | jq -c -r 'map(select((.name == "'"$KSQLDB_NAME"'") and (.kafka == "'"$CLUSTER"'")))')
  local FOUND_COUNT=$(echo "$FOUND_APP" | jq 'length')
  [[ $FOUND_COUNT -ne 0 ]] && {
      echo "$FOUND_APP" | jq -r '.[].id'
      return 0 
    } || {
      return 1
    }
}

function ccloud::create_ksqldb_app() {
  KSQLDB_NAME=$1
  CLUSTER=$2
  SERVICE_ACCOUNT_ID=$3
  

  KSQLDB=$(confluent ksql cluster create --cluster $CLUSTER --credential-identity $SERVICE_ACCOUNT_ID  --csu 1 -o json "$KSQLDB_NAME" | jq -r ".id")
  echo $KSQLDB

  return 0
}
function ccloud::maybe_create_ksqldb_app() {
  KSQLDB_NAME=$1
  CLUSTER=$2
  # colon deliminated credentials (APIKEY:APISECRET)
  local ksqlDB_kafka_creds=$3
  
  APP_ID=$(ccloud::find_ksqldb_app $KSQLDB_NAME $CLUSTER)
  if [ $? -eq 0 ]
  then
    echo $APP_ID
  else
    ccloud::create_ksqldb_app "$KSQLDB_NAME" "$CLUSTER" "$ksqlDB_kafka_creds"
  fi

  return 0
}

function ccloud::grant_envadmin_access() {
  SERVICE_ACCOUNT_ID=$1
  ENVIRONMENT=$2
  # Setting default QUIET=false to surface potential errors
  QUIET="${QUIET:-false}"
  [[ $QUIET == "true" ]] &&
    local REDIRECT_TO="/dev/null" ||
    local REDIRECT_TO="/dev/tty"

  echo "Adding role-binding to ${SERVICE_ACCOUNT_ID} on ${ENVIRONMENT}"
  confluent iam rbac role-binding create --principal User:${SERVICE_ACCOUNT_ID} --role EnvironmentAdmin --environment ${ENVIRONMENT} -o json &>"$REDIRECT_TO"

  echo -e "\nWaiting for role-binding to propagate\n"
  sleep 30

  confluent iam rbac role-binding list --principal User:${SERVICE_ACCOUNT_ID} --role EnvironmentAdmin --environment ${ENVIRONMENT} -o json &>"$REDIRECT_TO"
  return 0
}


# ccloud::set_cli_from_config_file enables users to switch between multiple Confluent Cloud clusters
# generated by ccloud-stack
function ccloud::set_cli_from_config_file() {
  [ -z "$1" ] && {
    echo "ccloud::validate_ccloud_config expects one parameter (configuration file with Confluent Cloud connection information)"
    exit 1
  }

  local cfg_file="$1"
  ccloud::validate_logged_in_cli
  ccloud::validate_ccloud_config $cfg_file
  ccloud::generate_configs $cfg_file
  source delta_configs/env.delta
  ccloud::set_cli_from_env_params

  return 0
}



# ccloud::set_cli_from_env_params enables users to switch between multiple Confluent Cloud clusters
# The provided credentials must have appropriate authorization already set
# - ENVIRONMENT_ID
# - KAFKA_CLUSTER_ID
# - CLOUD_KEY
# - CLOUD_SECRET
function ccloud::set_cli_from_env_params() {

  # Check minimum parameters
  if [[ -z "$ENVIRONMENT_ID" || \
           "$ENVIRONMENT_ID" == -1 || \
        -z "$KAFKA_CLUSTER_ID" || \
           "$KAFKA_CLUSTER_ID" == -1 || \
        -z "$CLOUD_KEY" || \
        -z "$CLOUD_SECRET" ]]; then
     echo "ERROR: Missing at least one environment parameter.  Please troubleshoot and run again."
     return 1
  fi

  confluent environment use $ENVIRONMENT_ID
  confluent kafka cluster use $KAFKA_CLUSTER_ID
  confluent api-key store "$CLOUD_KEY" "$CLOUD_SECRET" --resource ${KAFKA_CLUSTER_ID}
  confluent api-key use "$CLOUD_KEY" --resource ${KAFKA_CLUSTER_ID}

  return 0

}

function ccloud::validate_ccloud_config() {
  [ -z "$1" ] && {
    echo "ccloud::validate_ccloud_config expects one parameter (configuration file with Confluent Cloud connection information)"
    exit 1
  }

  local cfg_file="$1"
  local bootstrap=$(grep "bootstrap\.servers" "$cfg_file" | cut -d'=' -f2-)
  [ -z "$bootstrap" ] && {
    echo "ERROR: Cannot read the 'bootstrap.servers' key-value pair from $cfg_file."
    exit 1;
  }
  return 0;
}

function ccloud::validate_ksqldb_up() {
  [ -z "$1" ] && {
    echo "ccloud::validate_ksqldb_up expects one parameter (ksqldb endpoint)"
    exit 1
  }

  [ $# -gt 1 ] && echo "WARN: ccloud::validate_ksqldb_up function expects one parameter"

  local ksqldb_endpoint=$1

  ccloud::validate_logged_in_cli || exit 1

  local ksqldb_meta=$(confluent ksql cluster list -o json | jq -r 'map(select(.endpoint == "'"$ksqldb_endpoint"'")) | .[]')

  local ksqldb_appid=$(echo "$ksqldb_meta" | jq -r '.id')
  if [[ "$ksqldb_appid" == "" ]]; then
    echo "ERROR: Confluent Cloud ksqlDB endpoint $ksqldb_endpoint is not found. Provision a ksqlDB cluster via the Confluent Cloud UI and add the configuration parameter ksql.endpoint and ksql.basic.auth.user.info into your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi

  local ksqldb_status=$(echo "$ksqldb_meta" | jq -r '.status')
  if [[ $ksqldb_status != "PROVISIONED" ]]; then
    echo "ERROR: Confluent Cloud ksqlDB endpoint $ksqldb_endpoint with id $ksqlDBAppId is not in PROVISIONED state. Troubleshoot and try again."
    exit 1
  fi

  return 0
}

function ccloud::validate_azure_account() {
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

function ccloud::validate_credentials_ksqldb() {
  ksqldb_endpoint=$1
  ccloud_config_file=$2
  credentials=$3

  response=$(curl ${ksqldb_endpoint}/info \
             -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
             --silent \
             -u $credentials)
  if [[ "$response" =~ "Unauthorized" ]]; then
    echo "ERROR: Authorization failed to the ksqlDB cluster. Check your ksqlDB credentials set in the configuration parameter ksql.basic.auth.user.info in your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi

  echo "Validated credentials to Confluent Cloud ksqlDB at $ksqldb_endpoint"
  return 0
}

function ccloud::create_connector() {
  file=$1

  echo -e "\nCreating connector from $file\n"

  # About the Confluent CLI command 'confluent connect cluster create':
  # - Typical usage of this CLI would be 'confluent connect cluster create --config <filename>'
  # - However, in this example, the connector's configuration file contains parameters that need to be first substituted
  #   so the CLI command includes eval and heredoc.
  # - The '-vvv' is added for verbose output
  confluent connect cluster create -vvv --config-file <(eval "cat <<EOF
$(<$file)
EOF
")
  if [[ $? != 0 ]]; then
    echo "ERROR: Exit status was not 0 while creating connector from $file.  Please troubleshoot and try again"
    exit 1
  fi

  return 0
}

function ccloud::validate_connector_up() {
  confluent connect cluster list -o json | jq -e 'map(select(.name == "'"$1"'" and .status == "RUNNING")) | .[]' > /dev/null 2>&1
}

function ccloud::wait_for_connector_up() {
  filename=$1
  maxWait=$2

  connectorName=$(cat $filename | jq -r .name)
  echo "Waiting up to $maxWait seconds for connector $filename ($connectorName) to be RUNNING"
  ccloud::retry $maxWait ccloud::validate_connector_up $connectorName || exit 1
  echo "Connector $filename ($connectorName) is RUNNING"

  return 0
}


function ccloud::validate_ccloud_ksqldb_endpoint_ready() {
  KSQLDB_ENDPOINT=$1

  STATUS=$(confluent ksql cluster list -o json | jq -r 'map(select(.endpoint == "'"$KSQLDB_ENDPOINT"'")) | .[].status' | grep PROVISIONED)
  if [[ "$STATUS" == "" ]]; then
    return 1
  fi

  return 0
}

function ccloud::validate_ccloud_cluster_ready() {
  confluent kafka topic list &>/dev/null
  return $?
}

function ccloud::validate_topic_exists() {
  topic=$1

  confluent kafka topic describe $topic &>/dev/null
  return $?
}

function ccloud::validate_subject_exists() {
  subject=$1
  sr_url=$2
  sr_credentials=$3

  curl --silent -u $sr_credentials $sr_url/subjects/$subject/versions/latest | jq -r ".subject" | grep $subject > /dev/null
  return $?
}

function ccloud::login_cli(){
  URL=$1
  EMAIL=$2
  PASSWORD=$3

  ccloud::validate_expect_installed

  echo -e "\n# Login"
  OUTPUT=$(
  expect <<END
    log_user 1
    spawn confluent login --url $URL --prompt -vvvv
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
    echo "Failed to log into your cluster. Please check all parameters and run again."
  fi

  return 0
}

function ccloud::get_service_account() {

  [ -z "$1" ] && {
    echo "ccloud::get_service_account expects one parameter (API Key)"
    exit 1
  }

  [ $# -gt 1 ] && echo "WARN: ccloud::get_service_account function expects one parameter, received two"

  local key="$1"

  serviceAccount=$(confluent api-key list -o json | jq -r -c 'map(select((.key == "'"$key"'"))) | .[].owner_id')
  if [[ "$serviceAccount" == "" ]]; then
    echo "ERROR: Could not associate key $key to a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi
  if ! [[ "$serviceAccount" =~ ^sa-[a-z0-9]+$ ]]; then
    echo "ERROR: $serviceAccount value is not a valid value for a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi

  echo "$serviceAccount"

  return 0
}

function ccloud::create_acls_connector() {
  serviceAccount=$1

  confluent kafka acl create --allow --service-account $serviceAccount --operations DESCRIBE --cluster-scope
  confluent kafka acl create --allow --service-account $serviceAccount --operations CREATE,WRITE --prefix --topic dlq-lcc
  confluent kafka acl create --allow --service-account $serviceAccount --operations READ --prefix --consumer-group connect-lcc

  return 0
}

function ccloud::create_acls_control_center() {
  serviceAccount=$1

  echo "Confluent Control Center: creating _confluent-command and ACLs for service account $serviceAccount"
  confluent kafka topic create _confluent-command --partitions 1
  confluent kafka acl create --allow --service-account $serviceAccount --operations WRITE,READ,CREATE --topic _confluent --prefix
  confluent kafka acl create --allow --service-account $serviceAccount --operations READ,CREATE --consumer-group _confluent --prefix
  

  return 0
}


function ccloud::create_acls_replicator() {
  serviceAccount=$1
  topic=$2

  confluent kafka acl create --allow --service-account $serviceAccount --operations CREATE,WRITE,READ,DESCRIBE,DESCRIBE-CONFIGS,ALTER-CONFIGS --topic $topic
  confluent kafka acl create --allow --service-account $serviceAccount --operations DESCRIBE --cluster-scope

  return 0
}

function ccloud::create_acls_connect_topics() {
  serviceAccount=$1

  echo "Connect: creating topics and ACLs for service account $serviceAccount"

  TOPIC=connect-demo-configs
  confluent kafka topic create $TOPIC --partitions 1 --config "cleanup.policy=compact"
  confluent kafka acl create --allow --service-account $serviceAccount --operations WRITE,READ --topic $TOPIC --prefix

  TOPIC=connect-demo-offsets
  confluent kafka topic create $TOPIC --partitions 6 --config "cleanup.policy=compact"
  confluent kafka acl create --allow --service-account $serviceAccount --operations WRITE,READ --topic $TOPIC --prefix
  
  TOPIC=connect-demo-statuses 
  confluent kafka topic create $TOPIC --partitions 3 --config "cleanup.policy=compact"
  confluent kafka acl create --allow --service-account $serviceAccount --operations WRITE,READ --topic $TOPIC --prefix
  

  for TOPIC in _confluent-monitoring _confluent-command ; do
    confluent kafka topic create $TOPIC &>/dev/null
    confluent kafka acl create --allow --service-account $serviceAccount --operations WRITE,READ --topic $TOPIC --prefix
  done
 
  confluent kafka acl create --allow --service-account $serviceAccount --operations READ --consumer-group connect-cloud

  echo "Connectors: creating topics and ACLs for service account $serviceAccount"
  confluent kafka acl create --allow --service-account $serviceAccount --operations READ --consumer-group connect-replicator
  confluent kafka acl create --allow --service-account $serviceAccount --operations describe --cluster-scope

  return 0
}

function ccloud::validate_ccloud_stack_up() {
  CLOUD_KEY=$1
  CONFIG_FILE=$2
  enable_ksqldb=$3

  if [ -z "$enable_ksqldb" ]; then
    enable_ksqldb=true
  fi

  ccloud::validate_environment_set || exit 1
  ccloud::set_kafka_cluster_use_from_api_key "$CLOUD_KEY" || exit 1
  ccloud::validate_schema_registry_up "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO" "$SCHEMA_REGISTRY_URL" || exit 1
  if $enable_ksqldb ; then
    ccloud::validate_ksqldb_up "$KSQLDB_ENDPOINT" || exit 1
    ccloud::validate_credentials_ksqldb "$KSQLDB_ENDPOINT" "$CONFIG_FILE" "$KSQLDB_BASIC_AUTH_USER_INFO" || exit 1
  fi
}

function ccloud::validate_environment_set() {
  confluent environment list | grep '*' &>/dev/null || {
    echo "ERROR: could not determine if environment is set. Run 'confluent environment list' and set 'confluent environment use' and try again"
    exit 1
  }

  return 0
}

function ccloud::set_kafka_cluster_use_from_api_key() {
  [ -z "$1" ] && {
    echo "ccloud::set_kafka_cluster_use_from_api_key expects one parameter (API Key)"
    exit 1
  }

  [ $# -gt 1 ] && echo "WARN: ccloud::set_kafka_cluster_use_from_api_key function expects one parameter, received two"

  local key="$1"

  local kafkaCluster=$(confluent api-key list -o json | jq -r -c 'map(select((.key == "'"$key"'" and .resource_type == "kafka"))) | .[].resource_id')
  if [[ "$kafkaCluster" == "" ]]; then
    echo "ERROR: Could not associate key $key to a Confluent Cloud Kafka cluster. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi

  confluent kafka cluster use $kafkaCluster
  local endpoint=$(confluent kafka cluster describe $kafkaCluster -o json | jq -r ".endpoint" | cut -c 12-)
  echo -e "\nAssociated key $key to Confluent Cloud Kafka cluster $kafkaCluster at $endpoint"

  return 0
}

###
# Deprecated 10/28/2020, use ccloud::set_kafka_cluster_use_from_api_key
###
function ccloud::set_kafka_cluster_use() {
  echo "WARN: set_kafka_cluster_use is deprecated, use ccloud::set_kafka_cluster_use_from_api_key"
  ccloud::set_kafka_cluster_use_from_api_key "$@"
}


function ccloud::maybe_create_and_use_environment() {

  ENVIRONMENT_NAME=$1

  if [[ -z "$ENVIRONMENT" ]];
  then
    ENVIRONMENT=$(ccloud::create_and_use_environment $ENVIRONMENT_NAME)
    (($? != 0)) && { echo "$ENVIRONMENT"; exit 1; }
  else
    confluent environment use $ENVIRONMENT || exit 1
  fi

  echo "$ENVIRONMENT"

  return 0

}


#
# ccloud-stack documentation:
# https://docs.confluent.io/platform/current/tutorials/examples/ccloud/docs/ccloud-stack.html
#
function ccloud::create_ccloud_stack() {
  ccloud::validate_version_cli $CLI_MIN_VERSION || exit 1

  QUIET="${QUIET:-false}"
  REPLICATION_FACTOR=${REPLICATION_FACTOR:-3}
  enable_ksqldb=${1:-false}
  EXAMPLE=${EXAMPLE:-ccloud-stack-function}
  CHECK_CREDIT_CARD="${CHECK_CREDIT_CARD:-false}"

  # Check if credit card is on file, which is required for cluster creation
  if $CHECK_CREDIT_CARD && [[ $(confluent admin payment describe) =~ "not found" ]]; then
    echo "ERROR: No credit card on file. Add a payment method and try again."
    echo "If you are using a cloud provider's Marketplace, see documentation for a workaround: https://docs.confluent.io/platform/current/tutorials/examples/ccloud/docs/ccloud-stack.html#running-with-marketplace"
    exit 1
  fi

  if [[ -z "$SERVICE_ACCOUNT_ID" ]]; then
    # Service Account is not received so it will be created
    local RANDOM_NUM=$((1 + RANDOM % 1000000))
    SERVICE_NAME=${SERVICE_NAME:-"demo-app-$RANDOM_NUM"}
    SERVICE_ACCOUNT_ID=$(ccloud::create_service_account $SERVICE_NAME)
  fi

  if [[ "$SERVICE_NAME" == "" ]]; then
    echo "ERROR: SERVICE_NAME is not defined. If you are providing the SERVICE_ACCOUNT_ID to this function please also provide the SERVICE_NAME"
    exit 1
  fi

  echo "Creating Confluent Cloud stack for service account $SERVICE_NAME, ID: $SERVICE_ACCOUNT_ID."

  ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-"ccloud-stack-$SERVICE_ACCOUNT_ID-$EXAMPLE"}
  ENVIRONMENT=$(ccloud::maybe_create_and_use_environment "$ENVIRONMENT_NAME")

  CLUSTER_NAME=${CLUSTER_NAME:-"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"}
  CLUSTER_CLOUD="${CLUSTER_CLOUD:-aws}"
  CLUSTER_REGION="${CLUSTER_REGION:-us-west-2}"
  CLUSTER=$(ccloud::maybe_create_and_use_cluster "$CLUSTER_NAME" $CLUSTER_CLOUD $CLUSTER_REGION)
  (($? != 0)) && { echo "$CLUSTER"; exit 1; }
  if [[ "$CLUSTER" == "" ]] ; then
    echo "Kafka cluster id is empty"
    echo "ERROR: Could not create cluster. Please troubleshoot."
    exit 1
  fi

  # Sometimes bootstrap.servers is empty so testing a sleep
  sleep 3

  BOOTSTRAP_SERVERS=$(confluent kafka cluster describe $CLUSTER -o json | jq -r ".endpoint" | cut -c 12-)
  CLUSTER_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $CLUSTER)
  if [[ "$CLUSTER_CREDS" == "" ]] ; then
    echo "Credentials are empty"
    echo "ERROR: Could not create credentials."
    exit 1
  fi

  MAX_WAIT=720
  echo ""
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud cluster to be ready and for credentials to propagate"
  ccloud::retry $MAX_WAIT ccloud::validate_ccloud_cluster_ready || exit 1

  # Estimating another 80s wait still sometimes required
  WARMUP_TIME=${WARMUP_TIME:-80}
  echo -e "Sleeping an additional ${WARMUP_TIME} seconds to ensure propagation of all metadata\n"
  sleep $WARMUP_TIME 

  ccloud::grant_envadmin_access $SERVICE_ACCOUNT_ID $ENVIRONMENT

  SCHEMA_REGISTRY_GEO="${SCHEMA_REGISTRY_GEO:-us}"
  SCHEMA_REGISTRY=$(ccloud::enable_schema_registry $CLUSTER_CLOUD $SCHEMA_REGISTRY_GEO)
  # FF-11908/DEVX-2800: sometimes describe fails immediately after enable, adding sleep
  sleep 10
  SCHEMA_REGISTRY_ENDPOINT=$(confluent schema-registry cluster describe -o json | jq -r ".endpoint_url")
  SCHEMA_REGISTRY_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $SCHEMA_REGISTRY)
  
  if $enable_ksqldb ; then
    KSQLDB_NAME=${KSQLDB_NAME:-"demo-ksqldb-$SERVICE_ACCOUNT_ID"}
    KSQLDB=$(ccloud::maybe_create_ksqldb_app "$KSQLDB_NAME" $CLUSTER "$SERVICE_ACCOUNT_ID")
    KSQLDB_ENDPOINT=$(confluent ksql cluster describe $KSQLDB -o json | jq -r ".endpoint")
    KSQLDB_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $KSQLDB)
  fi

  CLOUD_API_KEY=`echo $CLUSTER_CREDS | awk -F: '{print $1}'`
  CLOUD_API_SECRET=`echo $CLUSTER_CREDS | awk -F: '{print $2}'`
  confluent api-key use $CLOUD_API_KEY --resource ${CLUSTER}

  if [[ -z "$SKIP_CONFIG_FILE_WRITE" ]]; then
    if [[ -z "$CONFIG_FILE" ]]; then
      mkdir -p stack-configs
      CONFIG_FILE="stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"
    fi
  
    cat <<EOF > $CONFIG_FILE
# --------------------------------------
# Confluent Cloud connection information
# --------------------------------------
# ENVIRONMENT_ID=${ENVIRONMENT}
# SERVICE_ACCOUNT_ID=${SERVICE_ACCOUNT_ID}
# KAFKA_CLUSTER_ID=${CLUSTER}
# SCHEMA_REGISTRY_CLUSTER_ID=${SCHEMA_REGISTRY}
EOF
    if $enable_ksqldb ; then
      cat <<EOF >> $CONFIG_FILE
# KSQLDB APP ID: ${KSQLDB}
EOF
    fi
    cat <<EOF >> $CONFIG_FILE
# --------------------------------------
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${CLOUD_API_KEY}' password='${CLOUD_API_SECRET}';
basic.auth.credentials.source=USER_INFO
schema.registry.url=${SCHEMA_REGISTRY_ENDPOINT}
basic.auth.user.info=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'`:`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
replication.factor=${REPLICATION_FACTOR}
EOF
    if $enable_ksqldb ; then
      cat <<EOF >> $CONFIG_FILE
ksql.endpoint=${KSQLDB_ENDPOINT}
ksql.basic.auth.user.info=`echo $KSQLDB_CREDS | awk -F: '{print $1}'`:`echo $KSQLDB_CREDS | awk -F: '{print $2}'`
EOF
    fi

    echo
    echo "Client configuration file saved to: $CONFIG_FILE"
  fi

  return 0
}

function ccloud::destroy_ccloud_stack() {
  if [ $# -eq 0 ];then
    echo "ccloud::destroy_ccloud_stack requires a single parameter, the service account id."
    exit 1
  fi

  SERVICE_ACCOUNT_ID=$1
  ENVIRONMENT=${ENVIRONMENT:-$(ccloud::get_environment_id_from_service_id $SERVICE_ACCOUNT_ID)}

  confluent environment use $ENVIRONMENT || exit 1

  PRESERVE_ENVIRONMENT="${PRESERVE_ENVIRONMENT:-false}"

  ENVIRONMENT_NAME_PREFIX=${ENVIRONMENT_NAME_PREFIX:-"ccloud-stack-$SERVICE_ACCOUNT_ID"}
  CLUSTER_NAME=${CLUSTER_NAME:-"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"}
  CONFIG_FILE=${CONFIG_FILE:-"stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"}
  KSQLDB_NAME=${KSQLDB_NAME:-"demo-ksqldb-$SERVICE_ACCOUNT_ID"}

  # Setting default QUIET=false to surface potential errors
  QUIET="${QUIET:-false}"
  [[ $QUIET == "true" ]] && 
    local REDIRECT_TO="/dev/null" ||
    local REDIRECT_TO="/dev/tty"

  echo "Destroying Confluent Cloud stack associated to service account id $SERVICE_ACCOUNT_ID"

  local cluster_id=$(confluent kafka cluster list -o json | jq -r 'map(select(.name == "'"$CLUSTER_NAME"'")) | .[].id')
  echo "Using Cluster: $cluster_id"
  confluent kafka cluster use $cluster_id 2>/dev/null

  ksqldb_id_found=$(confluent ksql cluster list -o json | jq -r 'map(select(.name == "'"$KSQLDB_NAME"'")) | .[].id')
  if [[ $ksqldb_id_found != "" ]]; then
    echo "Deleting KSQLDB: $KSQLDB_NAME : $ksqldb_id_found"
    confluent ksql cluster delete $ksqldb_id_found --force &> "$REDIRECT_TO"
  fi

  # Delete connectors associated to this Kafka cluster, otherwise cluster deletion fails
  confluent connect cluster list --cluster $cluster_id -o json | jq -r '.[].id' | xargs -I{} confluent connect cluster delete {} --force

  echo "Deleting CLUSTER: $CLUSTER_NAME : $cluster_id"
  confluent kafka cluster delete $cluster_id --force &> "$REDIRECT_TO"

  # Delete API keys associated to the service account
  confluent api-key list --service-account $SERVICE_ACCOUNT_ID -o json | jq -r '.[].key' | xargs -I{} confluent api-key delete {} --force

  # Delete service account along with its role bindings
  confluent iam service-account delete $SERVICE_ACCOUNT_ID --force &>"$REDIRECT_TO" 

  if [[ $PRESERVE_ENVIRONMENT == "false" ]]; then
    local environment_id=$(confluent environment list -o json | jq -r 'map(select(.name | startswith("'"$ENVIRONMENT_NAME_PREFIX"'"))) | .[].id')
    if [[ "$environment_id" == "" ]]; then
      echo "WARNING: Could not find environment with name that starts with $ENVIRONMENT_NAME_PREFIX (did you create this ccloud-stack reusing an existing environment?)"
    else
      echo "Deleting ENVIRONMENT: prefix $ENVIRONMENT_NAME_PREFIX : $environment_id"
      confluent environment delete $environment_id --force &> "$REDIRECT_TO"
    fi
  fi
  
  rm -f $CONFIG_FILE

  return 0
}

###############################################################################
# Overview:
#
# This code reads a local Confluent Cloud configuration file
# and writes delta configuration files into ./delta_configs for
# Confluent Platform components and clients connecting to Confluent Cloud.
#
# Confluent Platform Components:
# - Confluent Schema Registry
# - KSQL Data Generator
# - ksqlDB server
# - Confluent Replicator (executable)
# - Confluent Control Center
# - Confluent Metrics Reporter
# - Confluent REST Proxy
# - Kafka Connect
# - Kafka connector
# - Kafka command line tools
#
# Kafka Clients:
# - Java (Producer/Consumer)
# - Java (Streams)
# - librdkafka config
# - Python
# - .NET
# - Go
# - Node.js (https://github.com/Blizzard/node-rdkafka)
# - C++
#
# Documentation for using this script:
#
#   https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html
#
# Arguments:
#
#   CONFIG_FILE, defaults to ~/.ccloud/config
#
# Example CONFIG_FILE at ~/.ccloud/config
#
#   $ cat $HOME/.ccloud/config
#
#   bootstrap.servers=<BROKER ENDPOINT>
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<API KEY>' password='<API SECRET>';
#
# If you are using Confluent Cloud Schema Registry, add the following configuration parameters
#
#   basic.auth.credentials.source=USER_INFO
#   basic.auth.user.info=<SR API KEY>:<SR API SECRET>
#   schema.registry.url=https://<SR ENDPOINT>
#
# If you are using Confluent Cloud ksqlDB, add the following configuration parameters
#
#   ksql.endpoint=<ksqlDB ENDPOINT>
#   ksql.basic.auth.user.info=<ksqlDB API KEY>:<ksqlDB API SECRET>
#
################################################################################
function ccloud::generate_configs() {
  CONFIG_FILE=$1
  if [[ -z "$CONFIG_FILE" ]]; then
    CONFIG_FILE=~/.ccloud/config
  fi
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "File $CONFIG_FILE is not found.  Please create this properties file to connect to your Confluent Cloud cluster and then try again"
    echo "See https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html for more information"
    return 1
  fi
  
  # Set permissions
  PERM=600
  if ls --version 2>/dev/null | grep -q 'coreutils' ; then
    # GNU binutils
    PERM=$(stat -c "%a" $CONFIG_FILE)
  else
    # BSD
    PERM=$(stat -f "%OLp" $CONFIG_FILE)
  fi
  
  # Make destination
  DEST="delta_configs"
  mkdir -p $DEST

  echo -e "\nGenerating component configurations from $CONFIG_FILE and saving to the folder $DEST\n"
  
  ################################################################################
  # Glean parameters from the Confluent Cloud configuration file
  ################################################################################
  
  # Kafka cluster
  BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS/\\/}
  SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CONFIG_FILE | cut -d'=' -f2- )
  SASL_JAAS_CONFIG_PROPERTY_FORMAT=${SASL_JAAS_CONFIG/username\\=/username=}
  SASL_JAAS_CONFIG_PROPERTY_FORMAT=${SASL_JAAS_CONFIG_PROPERTY_FORMAT/password\\=/password=}
  CLOUD_KEY=$( echo $SASL_JAAS_CONFIG | awk '{print $3}' | awk -F"'" '$0=$2' )
  CLOUD_SECRET=$( echo $SASL_JAAS_CONFIG | awk '{print $4}' | awk -F"'" '$0=$2' )
  
  # Schema Registry
  BASIC_AUTH_CREDENTIALS_SOURCE=$( grep "^basic.auth.credentials.source" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$( grep "^basic.auth.user.info" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  SCHEMA_REGISTRY_URL=$( grep "^schema.registry.url" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  
  # ksqlDB
  KSQLDB_ENDPOINT=$( grep "^ksql.endpoint" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  KSQLDB_BASIC_AUTH_USER_INFO=$( grep "^ksql.basic.auth.user.info" $CONFIG_FILE | awk -F'=' '{print $2;}' )

  # These are optional if they exist in the configuration file
  ENVIRONMENT_ID=$( grep "ENVIRONMENT_ID" $CONFIG_FILE | awk -F'=' 'END { if ($2) print $2; else print "-1" }')
  SERVICE_ACCOUNT_ID=$( grep "SERVICE_ACCOUNT_ID" $CONFIG_FILE | awk -F'=' 'END { if ($2) print $2; else print "-1" }')
  KAFKA_CLUSTER_ID=$( grep "KAFKA_CLUSTER_ID" $CONFIG_FILE | awk -F'=' 'END { if ($2) print $2; else print "-1" }')
  SCHEMA_REGISTRY_CLUSTER_ID=$( grep "SCHEMA_REGISTRY_CLUSTER_ID" $CONFIG_FILE | awk -F'=' 'END { if ($2) print $2; else print "-1" }')
  KSQLDB_APP_ID=$( grep "KSQLDB_APP_ID" $CONFIG_FILE | awk -F'=' 'END { if ($2) print $2; else print "-1" }')
  
  ################################################################################
  # Build configuration file with Confluent Cloud connection parameters and
  # Confluent Monitoring Interceptors for Streams Monitoring in Confluent Control Center
  ################################################################################
  INTERCEPTORS_CONFIG_FILE=$DEST/interceptors-ccloud.config
  rm -f $INTERCEPTORS_CONFIG_FILE
  echo "# Configuration derived from $CONFIG_FILE" > $INTERCEPTORS_CONFIG_FILE
  while read -r line
  do
    # Skip lines that are commented out
    if [[ ! -z $line && ${line:0:1} == '#' ]]; then
      continue
    fi
    # Skip lines that contain just whitespace
    if [[ -z "${line// }" ]]; then
      continue
    fi
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      line=${line/\\/}
    fi
    echo $line >> $INTERCEPTORS_CONFIG_FILE
  done < "$CONFIG_FILE"
  echo -e "\n# Confluent Monitoring Interceptor specific configuration" >> $INTERCEPTORS_CONFIG_FILE
  while read -r line
  do
    # Skip lines that are commented out
    if [[ ! -z $line && ${line:0:1} == '#' ]]; then
      continue
    fi
    # Skip lines that contain just whitespace
    if [[ -z "${line// }" ]]; then
      continue
    fi
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      line=${line/\\/}
    fi
    if [[ ${line:0:4} == 'sasl' ||
          ${line:0:3} == 'ssl' ||
          ${line:0:8} == 'security' ||
          ${line:0:9} == 'bootstrap' ]]; then
      echo "confluent.monitoring.interceptor.$line" >> $INTERCEPTORS_CONFIG_FILE
    fi
  done < "$CONFIG_FILE"
  chmod $PERM $INTERCEPTORS_CONFIG_FILE
  
  ################################################################################
  # Confluent Schema Registry instance (local) for Confluent Cloud
  ################################################################################
  SR_CONFIG_DELTA=$DEST/schema-registry-ccloud.delta
  rm -f $SR_CONFIG_DELTA
  while read -r line
  do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:29} != 'basic.auth.credentials.source' && ${line:0:15} != 'schema.registry' ]]; then
        echo "kafkastore.$line" >> $SR_CONFIG_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  chmod $PERM $SR_CONFIG_DELTA
  
  ################################################################################
  # Confluent Replicator (executable) for Confluent Cloud
  ################################################################################
  REPLICATOR_PRODUCER_DELTA=$DEST/replicator-to-ccloud-producer.delta
  rm -f $REPLICATOR_PRODUCER_DELTA
  cp $INTERCEPTORS_CONFIG_FILE $REPLICATOR_PRODUCER_DELTA
  echo -e "\n# Confluent Replicator (executable) specific configuration" >> $REPLICATOR_PRODUCER_DELTA
  echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $REPLICATOR_PRODUCER_DELTA
  REPLICATOR_SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG
  REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\\=/=}
  REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\"/\\\"}
  chmod $PERM $REPLICATOR_PRODUCER_DELTA
  
  ################################################################################
  # ksqlDB Server runs locally and connects to Confluent Cloud
  ################################################################################
  KSQLDB_SERVER_DELTA=$DEST/ksqldb-server-ccloud.delta
  rm -f $KSQLDB_SERVER_DELTA
  cp $INTERCEPTORS_CONFIG_FILE $KSQLDB_SERVER_DELTA
  echo -e "\n# ksqlDB Server specific configuration" >> $KSQLDB_SERVER_DELTA
  echo "producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQLDB_SERVER_DELTA
  echo "consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor" >> $KSQLDB_SERVER_DELTA
  echo "ksql.streams.producer.retries=2147483647" >> $KSQLDB_SERVER_DELTA
  echo "ksql.streams.producer.confluent.batch.expiry.ms=9223372036854775807" >> $KSQLDB_SERVER_DELTA
  echo "ksql.streams.producer.request.timeout.ms=300000" >> $KSQLDB_SERVER_DELTA
  echo "ksql.streams.producer.max.block.ms=9223372036854775807" >> $KSQLDB_SERVER_DELTA
  echo "ksql.streams.replication.factor=3" >> $KSQLDB_SERVER_DELTA
  echo "ksql.internal.topic.replicas=3" >> $KSQLDB_SERVER_DELTA
  echo "ksql.sink.replicas=3" >> $KSQLDB_SERVER_DELTA
  echo -e "\n# Confluent Schema Registry configuration for ksqlDB Server" >> $KSQLDB_SERVER_DELTA
  while read -r line
  do
    if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
      echo "ksql.schema.registry.$line" >> $KSQLDB_SERVER_DELTA
    elif [[ ${line:0:15} == 'schema.registry' ]]; then
      echo "ksql.$line" >> $KSQLDB_SERVER_DELTA
    fi
  done < $CONFIG_FILE
  chmod $PERM $KSQLDB_SERVER_DELTA
  
  ################################################################################
  # KSQL DataGen for Confluent Cloud
  ################################################################################
  KSQL_DATAGEN_DELTA=$DEST/ksql-datagen.delta
  rm -f $KSQL_DATAGEN_DELTA
  cp $INTERCEPTORS_CONFIG_FILE $KSQL_DATAGEN_DELTA
  echo -e "\n# KSQL DataGen specific configuration" >> $KSQL_DATAGEN_DELTA
  echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQL_DATAGEN_DELTA
  echo -e "\n# Confluent Schema Registry configuration for KSQL DataGen" >> $KSQL_DATAGEN_DELTA
  while read -r line
  do
    if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
      echo "ksql.schema.registry.$line" >> $KSQL_DATAGEN_DELTA
    elif [[ ${line:0:15} == 'schema.registry' ]]; then
      echo "ksql.$line" >> $KSQL_DATAGEN_DELTA
    fi
  done < $CONFIG_FILE
  chmod $PERM $KSQL_DATAGEN_DELTA
  
  ################################################################################
  # Confluent Control Center runs locally, monitors Confluent Cloud, and uses Confluent Cloud cluster as the backstore
  ################################################################################
  C3_DELTA=$DEST/control-center-ccloud.delta
  rm -f $C3_DELTA
  echo -e "\n# Confluent Control Center specific configuration" >> $C3_DELTA
  while read -r line
    do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:9} == 'bootstrap' ]]; then
        line=${line/\\/}
        echo "$line" >> $C3_DELTA
      fi
      if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
        echo "confluent.controlcenter.streams.$line" >> $C3_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  # max.message.bytes is enforced to 8MB in Confluent Cloud
  echo "confluent.metrics.topic.max.message.bytes=8388608" >> $C3_DELTA
  echo -e "\n# Confluent Schema Registry configuration for Confluent Control Center" >> $C3_DELTA
  while read -r line
  do
    if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
      echo "confluent.controlcenter.schema.registry.$line" >> $C3_DELTA
    elif [[ ${line:0:15} == 'schema.registry' ]]; then
      echo "confluent.controlcenter.$line" >> $C3_DELTA
    fi
  done < $CONFIG_FILE
  chmod $PERM $C3_DELTA
  
  ################################################################################
  # Confluent Metrics Reporter to Confluent Cloud
  ################################################################################
  METRICS_REPORTER_DELTA=$DEST/metrics-reporter.delta
  rm -f $METRICS_REPORTER_DELTA
  echo "metric.reporters=io.confluent.metrics.reporter.ConfluentMetricsReporter" >> $METRICS_REPORTER_DELTA
  echo "confluent.metrics.reporter.topic.replicas=3" >> $METRICS_REPORTER_DELTA
  while read -r line
    do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:9} == 'bootstrap' || ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
        echo "confluent.metrics.reporter.$line" >> $METRICS_REPORTER_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  chmod $PERM $METRICS_REPORTER_DELTA
  
  ################################################################################
  # Confluent REST Proxy to Confluent Cloud
  ################################################################################
  REST_PROXY_DELTA=$DEST/rest-proxy.delta
  rm -f $REST_PROXY_DELTA
  while read -r line
    do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:9} == 'bootstrap' || ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
        echo "$line" >> $REST_PROXY_DELTA
        echo "client.$line" >> $REST_PROXY_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  echo -e "\n# Confluent Schema Registry configuration for REST Proxy" >> $REST_PROXY_DELTA
  while read -r line
  do
    if [[ ${line:0:29} == 'basic.auth.credentials.source' || ${line:0:36} == 'schema.registry.basic.auth.user.info' ]]; then
      echo "client.$line" >> $REST_PROXY_DELTA
    elif [[ ${line:0:19} == 'schema.registry.url' ]]; then
      echo "$line" >> $REST_PROXY_DELTA
    fi
  done < $CONFIG_FILE
  chmod $PERM $REST_PROXY_DELTA
  
  ################################################################################
  # Kafka Connect runs locally and connects to Confluent Cloud
  ################################################################################
  CONNECT_DELTA=$DEST/connect-ccloud.delta
  rm -f $CONNECT_DELTA
  cat <<EOF > $CONNECT_DELTA
# Configuration for embedded admin client
replication.factor=3
config.storage.replication.factor=3
offset.storage.replication.factor=3
status.storage.replication.factor=3

EOF
  while read -r line
    do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:9} == 'bootstrap' ]]; then
        line=${line/\\/}
        echo "$line" >> $CONNECT_DELTA
      fi
      if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
        echo "$line" >> $CONNECT_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  
  for prefix in "producer" "consumer" "producer.confluent.monitoring.interceptor" "consumer.confluent.monitoring.interceptor" ; do
  
  echo -e "\n# Configuration for embedded $prefix" >> $CONNECT_DELTA
  while read -r line
    do
    if [[ ! -z $line && ${line:0:1} != '#' ]]; then
      if [[ ${line:0:9} == 'bootstrap' ]]; then
        line=${line/\\/}
      fi
      if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
        echo "${prefix}.$line" >> $CONNECT_DELTA
      fi
    fi
  done < "$CONFIG_FILE"
  
  done
  
  
  cat <<EOF >> $CONNECT_DELTA

# Confluent Schema Registry for Kafka Connect
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.basic.auth.credentials.source=$BASIC_AUTH_CREDENTIALS_SOURCE
value.converter.schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
value.converter.schema.registry.url=$SCHEMA_REGISTRY_URL
EOF
  chmod $PERM $CONNECT_DELTA
  
  ################################################################################
  # Kafka connector
  ################################################################################
  CONNECTOR_DELTA=$DEST/connector-ccloud.delta
  rm -f $CONNECTOR_DELTA
  cat <<EOF >> $CONNECTOR_DELTA
// Confluent Schema Registry for Kafka connectors
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.basic.auth.credentials.source=$BASIC_AUTH_CREDENTIALS_SOURCE
value.converter.schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
value.converter.schema.registry.url=$SCHEMA_REGISTRY_URL
EOF
  chmod $PERM $CONNECTOR_DELTA
  
  ################################################################################
  # AK command line tools
  ################################################################################
  AK_TOOLS_DELTA=$DEST/ak-tools-ccloud.delta
  rm -f $AK_TOOLS_DELTA
  cp $CONFIG_FILE $AK_TOOLS_DELTA
  chmod $PERM $AK_TOOLS_DELTA
  
  
  ################################################################################
  # Java (Producer/Consumer)
  ################################################################################
  JAVA_PC_CONFIG=$DEST/java_producer_consumer.delta
  rm -f $JAVA_PC_CONFIG
  
  cat <<EOF >> $JAVA_PC_CONFIG
import java.util.Properties;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ConsumerConfig;
import org.apache.kafka.common.config.SaslConfigs;

Properties props = new Properties();

// Basic Confluent Cloud Connectivity
props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "$BOOTSTRAP_SERVERS");
props.put(ProducerConfig.REPLICATION_FACTOR_CONFIG, 3);
props.put(ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// Confluent Schema Registry for Java
props.put("basic.auth.credentials.source", "$BASIC_AUTH_CREDENTIALS_SOURCE");
props.put("schema.registry.basic.auth.user.info", "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO");
props.put("schema.registry.url", "$SCHEMA_REGISTRY_URL");

// Optimize Performance for Confluent Cloud
props.put(ProducerConfig.RETRIES_CONFIG, 2147483647);
props.put("producer.confluent.batch.expiry.ms", 9223372036854775807);
props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 300000);
props.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, 9223372036854775807);

// Required for Streams Monitoring in Confluent Control Center
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// .... additional configuration settings
EOF
  chmod $PERM $JAVA_PC_CONFIG
  
  ################################################################################
  # Java (Streams)
  ################################################################################
  JAVA_STREAMS_CONFIG=$DEST/java_streams.delta
  rm -f $JAVA_STREAMS_CONFIG
  
  cat <<EOF >> $JAVA_STREAMS_CONFIG
import java.util.Properties;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ConsumerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.streams.StreamsConfig;

Properties props = new Properties();

// Basic Confluent Cloud Connectivity
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.REPLICATION_FACTOR_CONFIG, 3);
props.put(StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// Confluent Schema Registry for Java
props.put("basic.auth.credentials.source", "$BASIC_AUTH_CREDENTIALS_SOURCE");
props.put("schema.registry.basic.auth.user.info", "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO");
props.put("schema.registry.url", "$SCHEMA_REGISTRY_URL");

// Optimize Performance for Confluent Cloud
props.put(StreamsConfig.producerPrefix(ProducerConfig.RETRIES_CONFIG), 2147483647);
props.put("producer.confluent.batch.expiry.ms", 9223372036854775807);
props.put(StreamsConfig.producerPrefix(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG), 300000);
props.put(StreamsConfig.producerPrefix(ProducerConfig.MAX_BLOCK_MS_CONFIG), 9223372036854775807);

// Required for Streams Monitoring in Confluent Control Center
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// .... additional configuration settings
EOF
  chmod $PERM $JAVA_STREAMS_CONFIG
  
  ################################################################################
  # librdkafka
  ################################################################################
  LIBRDKAFKA_CONFIG=$DEST/librdkafka.delta
  rm -f $LIBRDKAFKA_CONFIG
  
  cat <<EOF >> $LIBRDKAFKA_CONFIG
bootstrap.servers="$BOOTSTRAP_SERVERS"
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username="$CLOUD_KEY"
sasl.password="$CLOUD_SECRET"
schema.registry.url="$SCHEMA_REGISTRY_URL"
basic.auth.user.info="$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO"
EOF
  chmod $PERM $LIBRDKAFKA_CONFIG
  
  ################################################################################
  # Python
  ################################################################################
  PYTHON_CONFIG=$DEST/python.delta
  rm -f $PYTHON_CONFIG
  
  cat <<EOF >> $PYTHON_CONFIG
from confluent_kafka import Producer, Consumer, KafkaError

producer = Producer({
           'bootstrap.servers': '$BOOTSTRAP_SERVERS',
           'broker.version.fallback': '0.10.0.0',
           'api.version.fallback.ms': 0,
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': '$CLOUD_KEY',
           'sasl.password': '$CLOUD_SECRET',
           // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
           'plugin.library.paths': 'monitoring-interceptor',
           // .... additional configuration settings
})

consumer = Consumer({
           'bootstrap.servers': '$BOOTSTRAP_SERVERS',
           'broker.version.fallback': '0.10.0.0',
           'api.version.fallback.ms': 0,
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': '$CLOUD_KEY',
           'sasl.password': '$CLOUD_SECRET',
           // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
           'plugin.library.paths': 'monitoring-interceptor',
           // .... additional configuration settings
})
EOF
  chmod $PERM $PYTHON_CONFIG
  
  ################################################################################
  # .NET 
  ################################################################################
  DOTNET_CONFIG=$DEST/dotnet.delta
  rm -f $DOTNET_CONFIG
  
  cat <<EOF >> $DOTNET_CONFIG
using Confluent.Kafka;

var producerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "$BOOTSTRAP_SERVERS" },
    { "broker.version.fallback", "0.10.0.0" },
    { "api.version.fallback.ms", 0 },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    // { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // varies by distro
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .... additional configuration settings
};

var consumerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "$BOOTSTRAP_SERVERS" },
    { "broker.version.fallback", "0.10.0.0" },
    { "api.version.fallback.ms", 0 },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    // { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // varies by distro
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .... additional configuration settings
};
EOF
  chmod $PERM $DOTNET_CONFIG
  
  ################################################################################
  # Go
  ################################################################################
  GO_CONFIG=$DEST/go.delta
  rm -f $GO_CONFIG
  
  cat <<EOF >> $GO_CONFIG
import (
  "github.com/confluentinc/confluent-kafka-go/kafka"
  
 
producer, err := kafka.NewProducer(&kafka.ConfigMap{
           "bootstrap.servers": "$BOOTSTRAP_SERVERS",
          "broker.version.fallback": "0.10.0.0",
          "api.version.fallback.ms": 0,
          "sasl.mechanisms": "PLAIN",
          "security.protocol": "SASL_SSL",
          "sasl.username": "$CLOUD_KEY",
          "sasl.password": "$CLOUD_SECRET",
                 // "ssl.ca.location": "/usr/local/etc/openssl/cert.pem", // varies by distro
                 "plugin.library.paths": "monitoring-interceptor",
                 // .... additional configuration settings
                 })
 
consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
     "bootstrap.servers": "$BOOTSTRAP_SERVERS",
       "broker.version.fallback": "0.10.0.0",
       "api.version.fallback.ms": 0,
       "sasl.mechanisms": "PLAIN",
       "security.protocol": "SASL_SSL",
       "sasl.username": "$CLOUD_KEY",
       "sasl.password": "$CLOUD_SECRET",
                 // "ssl.ca.location": "/usr/local/etc/openssl/cert.pem", // varies by distro
       "session.timeout.ms": 6000,
                 "plugin.library.paths": "monitoring-interceptor",
                 // .... additional configuration settings
                 })
EOF
  chmod $PERM $GO_CONFIG
  
  ################################################################################
  # Node.js
  ################################################################################
  NODE_CONFIG=$DEST/node.delta
  rm -f $NODE_CONFIG
  
  cat <<EOF >> $NODE_CONFIG
var Kafka = require('node-rdkafka');

var producer = new Kafka.Producer({
    'metadata.broker.list': '$BOOTSTRAP_SERVERS',
    'sasl.mechanisms': 'PLAIN',
    'security.protocol': 'SASL_SSL',
    'sasl.username': '$CLOUD_KEY',
    'sasl.password': '$CLOUD_SECRET',
     // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
    'plugin.library.paths': 'monitoring-interceptor',
    // .... additional configuration settings
  });

var consumer = Kafka.KafkaConsumer.createReadStream({
    'metadata.broker.list': '$BOOTSTRAP_SERVERS',
    'sasl.mechanisms': 'PLAIN',
    'security.protocol': 'SASL_SSL',
    'sasl.username': '$CLOUD_KEY',
    'sasl.password': '$CLOUD_SECRET',
     // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
    'plugin.library.paths': 'monitoring-interceptor',
    // .... additional configuration settings
  }, {}, {
    topics: '<topic name>',
    waitInterval: 0,
    objectMode: false
});
EOF
  chmod $PERM $NODE_CONFIG
  
  ################################################################################
  # C++
  ################################################################################
  CPP_CONFIG=$DEST/cpp.delta
  rm -f $CPP_CONFIG
  
  cat <<EOF >> $CPP_CONFIG
#include <librdkafka/rdkafkacpp.h>

RdKafka::Conf *producerConfig = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);
if (producerConfig->set("metadata.broker.list", "$BOOTSTRAP_SERVERS", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.mechanisms", "PLAIN", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("security.protocol", "SASL_SSL", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.username", "$CLOUD_KEY", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.password", "$CLOUD_SECRET", errstr) != RdKafka::Conf::CONF_OK ||
    // producerConfig->set("ssl.ca.location", "/usr/local/etc/openssl/cert.pem", errstr) != RdKafka::Conf::CONF_OK || // varies by distro
    producerConfig->set("plugin.library.paths", "monitoring-interceptor", errstr) != RdKafka::Conf::CONF_OK ||
    // .... additional configuration settings
   ) {
        std::cerr << "Configuration failed: " << errstr << std::endl;
        exit(1);
}
RdKafka::Producer *producer = RdKafka::Producer::create(producerConfig, errstr);

RdKafka::Conf *consumerConfig = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);
if (consumerConfig->set("metadata.broker.list", "$BOOTSTRAP_SERVERS", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.mechanisms", "PLAIN", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("security.protocol", "SASL_SSL", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.username", "$CLOUD_KEY", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.password", "$CLOUD_SECRET", errstr) != RdKafka::Conf::CONF_OK ||
    // consumerConfig->set("ssl.ca.location", "/usr/local/etc/openssl/cert.pem", errstr) != RdKafka::Conf::CONF_OK || // varies by distro
    consumerConfig->set("plugin.library.paths", "monitoring-interceptor", errstr) != RdKafka::Conf::CONF_OK ||
    // .... additional configuration settings
   ) {
        std::cerr << "Configuration failed: " << errstr << std::endl;
        exit(1);
}
RdKafka::Consumer *consumer = RdKafka::Consumer::create(consumerConfig, errstr);
EOF
  chmod $PERM $CPP_CONFIG
  
  ################################################################################
  # ENV
  ################################################################################
  ENV_CONFIG=$DEST/env.delta
  rm -f $ENV_CONFIG
  
  cat <<EOF >> $ENV_CONFIG
export BOOTSTRAP_SERVERS="$BOOTSTRAP_SERVERS"
export SASL_JAAS_CONFIG="$SASL_JAAS_CONFIG"
export SASL_JAAS_CONFIG_PROPERTY_FORMAT="$SASL_JAAS_CONFIG_PROPERTY_FORMAT"
export REPLICATOR_SASL_JAAS_CONFIG="$REPLICATOR_SASL_JAAS_CONFIG"
export BASIC_AUTH_CREDENTIALS_SOURCE="$BASIC_AUTH_CREDENTIALS_SOURCE"
export SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO="$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO"
export SCHEMA_REGISTRY_URL="$SCHEMA_REGISTRY_URL"
export CLOUD_KEY="$CLOUD_KEY"
export CLOUD_SECRET="$CLOUD_SECRET"
export KSQLDB_ENDPOINT="$KSQLDB_ENDPOINT"
export KSQLDB_BASIC_AUTH_USER_INFO="$KSQLDB_BASIC_AUTH_USER_INFO"
export ENVIRONMENT_ID="$ENVIRONMENT_ID"
export SERVICE_ACCOUNT_ID="$SERVICE_ACCOUNT_ID"
export KAFKA_CLUSTER_ID="$KAFKA_CLUSTER_ID"
export SCHEMA_REGISTRY_CLUSTER_ID="$SCHEMA_REGISTRY_CLUSTER_ID"
export KSQLDB_APP_ID="$KSQLDB_APP_ID"
EOF
  chmod $PERM $ENV_CONFIG

  return 0
}

##############################################
# These are some duplicate functions from 
#  helper.sh to decouple the script files.  In 
#  the future we can work to remove this 
#  duplication if necessary
##############################################
function ccloud::retry() {
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
function ccloud::version_gt() { 
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}
