#!/bin/bash

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh
  
# Source demo-specific configurations
source config/demo.cfg

# Setup Azure container
export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
az storage container show --name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY 2>/dev/null
if [[ $? != 0 ]]; then
  echo "az storage container create --name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY"
  az storage container create --name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY
fi

ccloud::create_connector connectors/az_no_avro.json || exit 1
ccloud::wait_for_connector_up connectors/az_no_avro.json 240 || exit 1

# While Azure Blob Sink is in Preview, limit is only one connector of this type
# So these lines are to remain commented out until then
#ccloud::create_connector connectors/az_avro.json || exit 1
#ccloud::wait_for_connector_up connectors/az_avro.json 240 || exit 1

exit 0
