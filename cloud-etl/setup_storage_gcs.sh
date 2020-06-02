#!/bin/bash

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh
  
# Source demo-specific configurations
source config/demo.cfg

ccloud::validate_cloud_storage config/demo.cfg || exit 1

bucket_list=$(gsutil ls | grep $GCS_BUCKET)
if [[ ! "$bucket_list" =~ "$GCS_BUCKET" ]]; then
  echo "gsutil mb -l $STORAGE_REGION gs://$GCS_BUCKET"
  gsutil mb -l $STORAGE_REGION gs://$GCS_BUCKET
fi

ccloud::create_connector connectors/gcs_no_avro.json || exit 1
ccloud::wait_for_connector_up connectors/gcs_no_avro.json 240 || exit 1

ccloud::create_connector connectors/gcs_avro.json || exit 1
ccloud::wait_for_connector_up connectors/gcs_avro.json 240 || exit 1

exit 0
