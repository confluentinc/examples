#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_aws_rds_db_ready() {
  DB_INSTANCE_IDENTIFIER=$1

  STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER | jq -r ".DBInstances[0].DBInstanceStatus")
  if [[ "$STATUS" -eq "available" ]]; then
    return 1
  fi
  return 0
}

#################################################################
# Source: create and populate AWS RDS database
#################################################################

aws rds create-db-instance \
    --db-name confluentdemo \
    --db-instance-identifier confluentdemo \
    --engine postgres \
    --allocated-storage 20 \
    --db-instance-class db.t2.micro \
    --master-username pg \
    --master-user-password pg12345678 \
    --license-model postgresql-license \
    --region $RDS_REGION \
    --profile $AWS_PROFILE

MAX_WAIT=720
echo
echo "Waiting up to $MAX_WAIT seconds for AWS RDS PostgreSQL database to be available"
retry $MAX_WAIT check_aws_rds_db_ready "confluentdemo" || exit 1

CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier confluentdemo | jq -r ".DBInstances[0].Endpoint.Address")
CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier confluentdemo | jq -r ".DBInstances[0].Endpoint.Port")

exit 0
