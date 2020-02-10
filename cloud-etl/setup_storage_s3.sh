#!/bin/bash
  
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

aws s3api head-bucket --bucket "$STORAGE_BUCKET_NAME" --region $STORAGE_REGION --profile $AWS_PROFILE 2>/dev/null
if [[ $? != 0 ]]; then
  echo "aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION --profile $AWS_PROFILE"
  aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION --profile $AWS_PROFILE
fi

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $STORAGE_PROFILE)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $STORAGE_PROFILE)
create_connector_cloud connectors/s3_no_avro.json || exit 1
create_connector_cloud connectors/s3_avro.json || exit 1

exit 0
