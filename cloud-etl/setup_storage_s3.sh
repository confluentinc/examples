#!/bin/bash
  
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

aws s3api head-bucket --bucket "$S3_BUCKET" --region $STORAGE_REGION --profile $S3_PROFILE 2>/dev/null
if [[ $? != 0 ]]; then
  echo "aws s3api create-bucket --bucket $S3_BUCKET --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION --profile $S3_PROFILE"
  aws s3api create-bucket --bucket $S3_BUCKET --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION --profile $S3_PROFILE
  if [[ $? != 0 ]]; then
    echo "ERROR: Could not create S3 bucket $S3_BUCKET in region $STORAGE_REGION using the profile $S3_PROFILE. Troubleshoot and try again."
    exit 1
  fi
fi

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $S3_PROFILE)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $S3_PROFILE)
create_connector_cloud connectors/s3_no_avro.json || exit 1
create_connector_cloud connectors/s3_avro.json || exit 1

exit 0
