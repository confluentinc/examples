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
#   wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
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

# --------------------------------------------------------------
# Library
# --------------------------------------------------------------

function ccloud::prompt_continue_ccloud_demo() {
  echo "This example uses real Confluent Cloud resources."
  echo "To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it."
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
function ccloud::validate_ccloud_cli_installed() {
  if [[ $(type ccloud 2>&1) =~ "not found" ]]; then
    echo "'ccloud' is not found. Install Confluent Cloud CLI (https://docs.confluent.io/current/ccloud-cli/install.html) and try again"
    exit 1
  fi
}

function ccloud::validate_ccloud_cli_v2() {
  ccloud::validate_ccloud_cli_installed || exit 1

  if [[ -z $(ccloud version 2>&1 | grep "Go") ]]; then
    echo "This example requires the new Confluent Cloud CLI. Please update your version and try again."
    exit 1
  fi

  return 0
}

function ccloud::validate_logged_in_ccloud_cli() {
  ccloud::validate_ccloud_cli_v2 || exit 1

  if [[ "$(ccloud kafka cluster list 2>&1)" == "Error: You must log in to run that command." ]]; then
    echo "ERROR: Log into Confluent Cloud with the command 'ccloud login --save' before running the example. The '--save' argument saves your Confluent Cloud user login credentials or refresh token (in the case of SSO) to the local netrc file."
    exit 1
  fi

  return 0
}

function ccloud::get_version_ccloud_cli() {
  ccloud version | grep "^Version:" | cut -d':' -f2 | cut -d'v' -f2
}

function ccloud::validate_version_ccloud_cli() {

  ccloud::validate_ccloud_cli_installed || exit 1

  REQUIRED_CCLOUD_VER=${1:-"1.7.0"}
  CCLOUD_VER=$(ccloud::get_version_ccloud_cli)

  if ccloud::version_gt $REQUIRED_CCLOUD_VER $CCLOUD_VER; then
    echo "ccloud version ${REQUIRED_CCLOUD_VER} or greater is required.  Current reported version: ${CCLOUD_VER}"
    echo 'To update run: ccloud update'
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


function ccloud::create_and_use_environment() {
  ENVIRONMENT_NAME=$1

  OUTPUT=$(ccloud environment create $ENVIRONMENT_NAME -o json)
  (($? != 0)) && { echo "ERROR: Failed to create environment $ENVIRONMENT_NAME. Please troubleshoot (maybe run ./clean.sh) and run again"; exit 1; }
  ENVIRONMENT=$(echo "$OUTPUT" | jq -r ".id")
  ccloud environment use $ENVIRONMENT &>/dev/null

  echo $ENVIRONMENT

  return 0
}

function ccloud::find_cluster() {
  CLUSTER_NAME=$1
  CLUSTER_CLOUD=$2
  CLUSTER_REGION=$3

  local FOUND_CLUSTER=$(ccloud kafka cluster list -o json | jq -c -r '.[] | select((.name == "'"$CLUSTER_NAME"'") and (.provider == "'"$CLUSTER_CLOUD"'") and (.region == "'"$CLUSTER_REGION"'"))')
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
  
  OUTPUT=$(ccloud kafka cluster create "$CLUSTER_NAME" --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION 2>&1)
  (($? != 0)) && { echo "$OUTPUT"; exit 1; }
  CLUSTER=$(echo "$OUTPUT" | grep '| Id' | awk '{print $4;}')
  ccloud kafka cluster use $CLUSTER
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
    ccloud kafka cluster use $CLUSTER_ID
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

  OUTPUT=$(ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME  -o json)
  SERVICE_ACCOUNT_ID=$(echo "$OUTPUT" | jq -r ".id")

  echo $SERVICE_ACCOUNT_ID

  return 0
}

function ccloud::enable_schema_registry() {
  SCHEMA_REGISTRY_CLOUD=$1
  SCHEMA_REGISTRY_GEO=$2

  OUTPUT=$(ccloud schema-registry cluster enable --cloud $SCHEMA_REGISTRY_CLOUD --geo $SCHEMA_REGISTRY_GEO -o json)
  SCHEMA_REGISTRY=$(echo "$OUTPUT" | jq -r ".id")

  echo $SCHEMA_REGISTRY

  return 0
}

function ccloud::find_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2
  local FOUND_CRED=$(ccloud api-key list -o json | jq -c -r 'map(select((.resource_id == "'"$RESOURCE"'") and (.owner == "'"$SERVICE_ACCOUNT_ID"'")))')
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

  OUTPUT=$(ccloud api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json)
  API_KEY_SA=$(echo "$OUTPUT" | jq -r ".key")
  API_SECRET_SA=$(echo "$OUTPUT" | jq -r ".secret")

  echo "${API_KEY_SA}:${API_SECRET_SA}"

  return 0
}
#####################################################################
# The return from this function will be a colon ':' deliminted 
#   list, if the api-key is created the second element of the
#   list will the secret.  If the api-key is being reused
#   the second element of the list will be empty
#####################################################################
function ccloud::maybe_create_credentials_resource() {
  SERVICE_ACCOUNT_ID=$1
  RESOURCE=$2
  
  local KEY=$(ccloud::find_credentials_resource $SERVICE_ACCOUNT_ID $RESOURCE)
  [[ -z $KEY ]] && {
    ccloud::create_credentials_resource $SERVICE_ACCOUNT_ID $RESOURCE
  } || {
    echo "$KEY:"; # the secret cannot be retrieved from a found key, caller needs to handle this
    return 0
  }
}

function ccloud::find_ksqldb_app() {
  KSQLDB_NAME=$1
  CLUSTER=$2

  local FOUND_APP=$(ccloud ksql app list -o json | jq -c -r 'map(select((.name == "'"$KSQLDB_NAME"'") and (.kafka == "'"$CLUSTER"'")))')
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

  KSQLDB=$(ccloud ksql app create --cluster $CLUSTER -o json "$KSQLDB_NAME" | jq -r ".id")
  echo $KSQLDB

  return 0
}
function ccloud::maybe_create_ksqldb_app() {
  KSQLDB_NAME=$1
  CLUSTER=$2
  
  APP_ID=$(ccloud::find_ksqldb_app $KSQLDB_NAME $CLUSTER)
  if [ $? -eq 0 ]
  then
    echo $APP_ID
  else
    ccloud::create_ksqldb_app "$KSQLDB_NAME" "$CLUSTER"
  fi

  return 0
}

function ccloud::create_acls_all_resources_full_access() {
  SERVICE_ACCOUNT_ID=$1
  [[ $QUIET == "true" ]] && 
    local REDIRECT_TO="/dev/null" ||
    local REDIRECT_TO="/dev/stdout"

  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DELETE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE_CONFIGS --topic '*' &>"$REDIRECT_TO"

  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --consumer-group '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --consumer-group '*' &>"$REDIRECT_TO"

  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --transactional-id '*' &>"$REDIRECT_TO"
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --transactional-id '*' &>"$REDIRECT_TO"
  
  ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation IDEMPOTENT-WRITE --cluster-scope &>"$REDIRECT_TO"

  return 0
}

function ccloud::delete_acls_ccloud_stack() {
  SERVICE_ACCOUNT_ID=$1

  echo "Deleting ACLs for service account ID $SERVICE_ACCOUNT_ID"

  local REDIRECT_TO="/dev/null"

  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --topic '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE_CONFIGS --topic '*' &>"$REDIRECT_TO"

  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --consumer-group '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --consumer-group '*' &>"$REDIRECT_TO"

  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation DESCRIBE --transactional-id '*' &>"$REDIRECT_TO"
  ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --transactional-id '*' &>"$REDIRECT_TO"

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

  ccloud::validate_logged_in_ccloud_cli || exit 1

  local ksqldb_meta=$(ccloud ksql app list -o json | jq -r 'map(select(.endpoint == "'"$ksqldb_endpoint"'")) | .[]')

  local ksqldb_appid=$(echo "$ksqldb_meta" | jq -r '.id')
  if [[ "$ksqldb_appid" == "" ]]; then
    echo "ERROR: Confluent Cloud ksqlDB endpoint $ksqldb_endpoint is not found. Provision a ksqlDB cluster via the Confluent Cloud UI and add the configuration parameter ksql.endpoint and ksql.basic.auth.user.info into your Confluent Cloud configuration file at $ccloud_config_file and try again."
    exit 1
  fi

  local ksqldb_status=$(echo "$ksqldb_meta" | jq -r '.status')
  if [[ $ksqldb_status != "UP" ]]; then
    echo "ERROR: Confluent Cloud ksqlDB endpoint $ksqldb_endpoint with id $ksqlDBAppId is not in UP state. Troubleshoot and try again."
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

  # About the Confluent Cloud CLI command 'ccloud connector create':
  # - Typical usage of this CLI would be 'ccloud connector create --config <filename>'
  # - However, in this example, the connector's configuration file contains parameters that need to be first substituted
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

function ccloud::validate_connector_up() {
  ccloud connector list -o json | jq -e 'map(select(.name == "'"$1"'" and .status == "RUNNING")) | .[]' > /dev/null 2>&1
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

  ksqlDBAppId=$(ccloud ksql app list | grep "$KSQLDB_ENDPOINT" | awk '{print $1}')
  if [[ "$ksqlDBAppId" == "" ]]; then
    return 1
  fi
  STATUS=$(ccloud ksql app describe $ksqlDBAppId | grep "Status" | grep UP)
  if [[ "$STATUS" == "" ]]; then
    return 1
  fi

  return 0
}

function ccloud::validate_ccloud_cluster_ready() {
  ccloud kafka topic list &>/dev/null
  return $?
}

function ccloud::validate_topic_exists() {
  topic=$1

  ccloud kafka topic describe $topic &>/dev/null
  return $?
}

function ccloud::validate_subject_exists() {
  subject=$1
  sr_url=$2
  sr_credentials=$3

  curl --silent -u $sr_credentials $sr_url/subjects/$subject/versions/latest | jq -r ".subject" | grep $subject > /dev/null
  return $?
}

function ccloud::login_ccloud_cli(){

  URL=$1
  EMAIL=$2
  PASSWORD=$3

  ccloud::validate_expect_installed

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

function ccloud::get_service_account() {

  [ -z "$1" ] && {
    echo "ccloud::get_service_account expects one parameter (API Key)"
    exit 1
  }

  [ $# -gt 1 ] && echo "WARN: ccloud::get_service_account function expects one parameter, received two"

  local key="$1"

  serviceAccount=$(ccloud api-key list -o json | jq -r -c 'map(select((.key == "'"$key"'"))) | .[].owner')
  if [[ "$serviceAccount" == "" ]]; then
    echo "ERROR: Could not associate key $key to a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi
  if ! [[ "$serviceAccount" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: $serviceAccount value is not a valid value for a service account. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi

  echo "$serviceAccount"

  return 0
}

function ccloud::create_acls_connector() {
  serviceAccount=$1

  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE --cluster-scope
  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --prefix --topic dlq-lcc
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --prefix --topic dlq-lcc
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --prefix --consumer-group connect-lcc

  return 0
}

function ccloud::create_acls_control_center() {
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


function ccloud::create_acls_replicator() {
  serviceAccount=$1
  topic=$2

  ccloud kafka acl create --allow --service-account $serviceAccount --operation CREATE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE-CONFIGS --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation ALTER-CONFIGS --topic $topic
  ccloud kafka acl create --allow --service-account $serviceAccount --operation DESCRIBE --cluster-scope

  return 0
}

function ccloud::create_acls_connect_topics() {
  serviceAccount=$1

  echo "Connect: creating topics and ACLs for service account $serviceAccount"

  TOPIC=connect-demo-configs
  ccloud kafka topic create $TOPIC --partitions 1 --config "cleanup.policy=compact"
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $TOPIC --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $TOPIC --prefix

  TOPIC=connect-demo-offsets
  ccloud kafka topic create $TOPIC --partitions 6 --config "cleanup.policy=compact"
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $TOPIC --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $TOPIC --prefix
  
  TOPIC=connect-demo-statuses 
  ccloud kafka topic create $TOPIC --partitions 3 --config "cleanup.policy=compact"
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $TOPIC --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $TOPIC --prefix
  

  for TOPIC in _confluent-monitoring _confluent-command ; do
    ccloud kafka topic create $TOPIC &>/dev/null
    ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic $TOPIC --prefix
    ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic $TOPIC --prefix
  done
 
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-cloud

  echo "Connectors: creating topics and ACLs for service account $serviceAccount"
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --consumer-group connect-replicator
  ccloud kafka acl create --allow --service-account $serviceAccount --operation describe --cluster-scope

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
  ccloud environment list | grep '*' &>/dev/null || {
    echo "ERROR: could not determine if environment is set. Run 'ccloud environment list' and set 'ccloud environment use' and try again"
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

  local kafkaCluster=$(ccloud api-key list -o json | jq -r -c 'map(select((.key == "'"$key"'" and .resource_type == "kafka"))) | .[].resource_id')
  if [[ "$kafkaCluster" == "" ]]; then
    echo "ERROR: Could not associate key $key to a Confluent Cloud Kafka cluster. Verify your credentials, ensure the API key has a set resource type, and try again."
    exit 1
  fi

  ccloud kafka cluster use $kafkaCluster
  local endpoint=$(ccloud kafka cluster describe $kafkaCluster -o json | jq -r ".endpoint" | cut -c 12-)
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


#
# ccloud-stack documentation:
# https://docs.confluent.io/current/tutorials/examples/ccloud/docs/ccloud-stack.html
#
function ccloud::create_ccloud_stack() {
  QUIET="${QUIET:-true}"
  REPLICATION_FACTOR=${REPLICATION_FACTOR:-3}
  enable_ksqldb=${1:-false}

  # Check if credit card is on file, which is required for cluster creation
  if [[ $(ccloud admin payment describe) =~ "not found" ]]; then
    echo "ERROR: No credit card on file. Add a payment method and try again."
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

  if [[ -z "$ENVIRONMENT" ]]; 
  then
    # Environment is not received so it will be created
    ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-"demo-env-$SERVICE_ACCOUNT_ID"}
    ENVIRONMENT=$(ccloud::create_and_use_environment $ENVIRONMENT_NAME)
    (($? != 0)) && { echo "$ENVIRONMENT"; exit 1; }
  else
    ccloud environment use $ENVIRONMENT &>/dev/null
  fi
  
  CLUSTER_NAME=${CLUSTER_NAME:-"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"}
  CLUSTER_CLOUD="${CLUSTER_CLOUD:-aws}"
  CLUSTER_REGION="${CLUSTER_REGION:-us-west-2}"
  CLUSTER=$(ccloud::maybe_create_and_use_cluster "$CLUSTER_NAME" $CLUSTER_CLOUD $CLUSTER_REGION)
  (($? != 0)) && { echo "$CLUSTER"; exit 1; }
  if [[ "$CLUSTER" == "" ]] ; then
    echo "Kafka cluster id is empty"
    echo "ERROR: Could not create cluster. Please troubleshoot"
    exit 1
  fi
  BOOTSTRAP_SERVERS=$(ccloud kafka cluster describe $CLUSTER -o json | jq -r ".endpoint" | cut -c 12-)
  CLUSTER_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $CLUSTER)

  MAX_WAIT=720
  echo ""
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud cluster to be ready and for credentials to propagate"
  ccloud::retry $MAX_WAIT ccloud::validate_ccloud_cluster_ready || exit 1

  # Estimating another 80s wait still sometimes required
  WARMUP_TIME=${WARMUP_TIME:-80}
  echo "Sleeping an additional ${WARMUP_TIME} seconds to ensure propagation of all metadata"
  sleep $WARMUP_TIME 

  SCHEMA_REGISTRY_GEO="${SCHEMA_REGISTRY_GEO:-us}"
  SCHEMA_REGISTRY=$(ccloud::enable_schema_registry $CLUSTER_CLOUD $SCHEMA_REGISTRY_GEO)
  SCHEMA_REGISTRY_ENDPOINT=$(ccloud schema-registry cluster describe -o json | jq -r ".endpoint_url")
  SCHEMA_REGISTRY_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $SCHEMA_REGISTRY)
  
  if $enable_ksqldb ; then
    KSQLDB_NAME=${KSQLDB_NAME:-"demo-ksqldb-$SERVICE_ACCOUNT_ID"}
    KSQLDB=$(ccloud::maybe_create_ksqldb_app "$KSQLDB_NAME" $CLUSTER)
    KSQLDB_ENDPOINT=$(ccloud ksql app describe $KSQLDB -o json | jq -r ".endpoint")
    KSQLDB_CREDS=$(ccloud::maybe_create_credentials_resource $SERVICE_ACCOUNT_ID $KSQLDB)
    KSQLDB_SERVICE_ACCOUNT_ID=$(ccloud service-account list -o json 2>/dev/null | jq -r "map(select(.name == \"KSQL.$KSQLDB\")) | .[0].id")
    ccloud ksql app configure-acls $KSQLDB
  fi

  ccloud::create_acls_all_resources_full_access $SERVICE_ACCOUNT_ID

  CLOUD_API_KEY=`echo $CLUSTER_CREDS | awk -F: '{print $1}'`
  CLOUD_API_SECRET=`echo $CLUSTER_CREDS | awk -F: '{print $2}'`
  ccloud api-key use $CLOUD_API_KEY --resource ${CLUSTER}

  if [[ -z "$SKIP_CONFIG_FILE_WRITE" ]]; then
    if [[ -z "$CLIENT_CONFIG" ]]; then
      mkdir -p stack-configs
      CLIENT_CONFIG="stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"
    fi
  
    cat <<EOF > $CLIENT_CONFIG
# --------------------------------------
# Confluent Cloud connection information
# --------------------------------------
# ENVIRONMENT ID: ${ENVIRONMENT}
# SERVICE ACCOUNT ID: ${SERVICE_ACCOUNT_ID}
# KAFKA CLUSTER ID: ${CLUSTER}
# SCHEMA REGISTRY CLUSTER ID: ${SCHEMA_REGISTRY}
EOF
    if $enable_ksqldb ; then
      cat <<EOF >> $CLIENT_CONFIG
# KSQLDB APP ID: ${KSQLDB}
EOF
    fi
    cat <<EOF >> $CLIENT_CONFIG
# --------------------------------------
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${CLOUD_API_KEY}' password='${CLOUD_API_SECRET}';
basic.auth.credentials.source=USER_INFO
schema.registry.url=${SCHEMA_REGISTRY_ENDPOINT}
schema.registry.basic.auth.user.info=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'`:`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
replication.factor=${REPLICATION_FACTOR}
EOF
    if $enable_ksqldb ; then
      cat <<EOF >> $CLIENT_CONFIG
ksql.endpoint=${KSQLDB_ENDPOINT}
ksql.basic.auth.user.info=`echo $KSQLDB_CREDS | awk -F: '{print $1}'`:`echo $KSQLDB_CREDS | awk -F: '{print $2}'`
EOF
    fi

    echo
    echo "Client configuration file saved to: $CLIENT_CONFIG"
  fi

  return 0
}

function ccloud::destroy_ccloud_stack() {
  SERVICE_ACCOUNT_ID=$1

  PRESERVE_ENVIRONMENT="${PRESERVE_ENVIRONMENT:-false}"

  ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-"demo-env-$SERVICE_ACCOUNT_ID"}
  CLUSTER_NAME=${CLUSTER_NAME:-"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"}
  CLIENT_CONFIG=${CLIENT_CONFIG:-"stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config"}
  KSQLDB_NAME=${KSQLDB_NAME:-"demo-ksqldb-$SERVICE_ACCOUNT_ID"}

  # Setting default QUIET=false to surface potential deletion errors
  QUIET="${QUIET:-false}"
  [[ $QUIET == "true" ]] && 
    local REDIRECT_TO="/dev/null" ||
    local REDIRECT_TO="/dev/stdout"

  echo "Destroying Confluent Cloud stack associated to service account id $SERVICE_ACCOUNT_ID"

  # Delete API keys associated to the service account
  ccloud api-key list --service-account $SERVICE_ACCOUNT_ID -o json | jq -r '.[].key' | xargs -I{} ccloud api-key delete {}

  ccloud::delete_acls_ccloud_stack $SERVICE_ACCOUNT_ID
  ccloud service-account delete $SERVICE_ACCOUNT_ID &>"$REDIRECT_TO" 

  if [[ "$KSQLDB_ENDPOINT" != "" ]]; then # This is just a quick check, if set there is a KSQLDB in this stack
    local ksqldb_id=$(ccloud ksql app list -o json | jq -r 'map(select(.name == "'"$KSQLDB_NAME"'")) | .[].id')
    echo "Deleting KSQLDB: $KSQLDB_NAME : $ksqldb_id"
    ccloud ksql app delete $ksqldb_id &> "$REDIRECT_TO"
  fi

  local cluster_id=$(ccloud kafka cluster list -o json | jq -r 'map(select(.name == "'"$CLUSTER_NAME"'")) | .[].id')
  echo "Deleting CLUSTER: $CLUSTER_NAME : $cluster_id"
  ccloud kafka cluster delete $cluster_id &> "$REDIRECT_TO"

  if [[ $PRESERVE_ENVIRONMENT == "false" ]]; then
    local environment_id=$(ccloud environment list -o json | jq -r 'map(select(.name == "'"$ENVIRONMENT_NAME"'")) | .[].id')
    if [[ "$environment_id" == "" ]]; then
      echo "WARNING: Could not find environment with name $ENVIRONMENT_NAME (did you create this ccloud-stack reusing an existing environment?)"
    else
      echo "Deleting ENVIRONMENT: $ENVIRONMENT_NAME : $environment_id"
      ccloud environment delete $environment_id &> "$REDIRECT_TO"
    fi
  fi
  
  rm -f $CLIENT_CONFIG

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
