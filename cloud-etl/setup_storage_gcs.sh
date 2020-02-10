#!/bin/bash

# Source library
. ../utils/helper.sh
  
# Source demo-specific configurations
source config/demo.cfg

bucket_list=$(gsutil ls | grep $STORAGE_BUCKET_NAME)
if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
  echo "gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME"
  gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME
fi

create_connector_cloud connectors/gcs_no_avro.json || exit 1
create_connector_cloud connectors/gcs_avro.json || exit 1

exit 0
