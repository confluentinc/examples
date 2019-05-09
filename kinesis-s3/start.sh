#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.2 || exit
check_aws || exit

./stop.sh

confluent-hub install confluentinc/kafka-connect-kinesis:latest --no-prompt
confluent-hub install confluentinc/kafka-connect-s3:latest --no-prompt
confluent start
sleep 10

# Verify connector plugins were successfully installed
curl -sS localhost:8083/connector-plugins | jq '.[].class' | grep Kinesis
curl -sS localhost:8083/connector-plugins | jq '.[].class' | grep S3

source $HOME/.aws/credentials-demo

bucket_exists=$(aws s3api list-buckets --query "Buckets[].Name" | grep $BUCKET_NAME)
if [[ ! "$bucket_exists" =~ "$BUCKET_NAME" ]]; then
  echo "aws s3api create-bucket --bucket $BUCKET_NAME --region $DEMO_REGION --create-bucket-configuration LocationConstraint=$DEMO_REGION"
  aws s3api create-bucket --bucket $BUCKET_NAME --region $DEMO_REGION --create-bucket-configuration LocationConstraint=$DEMO_REGION
fi

if is_ce; then
  . ./connectors/submit_kinesis_config.sh
  . ./connectors/submit_s3_config.sh
fi

timeout 20 confluent consume t1 --from-beginning
echo "aws s3api list-objects --bucket $BUCKET_NAME"
aws s3api list-objects --bucket $BUCKET_NAME

#ksql http://localhost:8088 <<EOF
#run script 'ksql.commands';
#exit ;
#EOF

# TODO
# - rename credentials-demo
# - create kinesis stream and add messages
# - clean up AWS bucket
