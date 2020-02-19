#!/bin/bash

# Source library
. ../utils/helper.sh
  
# Source demo-specific configurations
source config/demo.cfg

bucket_list=$(gsutil ls | grep $GCS_BUCKET)
if [[ ! "$bucket_list" =~ "$GCS_BUCKET" ]]; then
  echo "gsutil mb -l $STORAGE_REGION gs://$GCS_BUCKET"
  gsutil mb -l $STORAGE_REGION gs://$GCS_BUCKET
fi

echo $GCS_CREDENTIALS_FILE
export GCS_CREDENTIALS=$(cat $GCS_CREDENTIALS_FILE | jq --slurp --raw-input | jq -r)
echo $GCS_CREDENTIALS

create_connector_cloud connectors/gcs_no_avro.json || exit 1
create_connector_cloud connectors/gcs_avro.json || exit 1

exit 0
