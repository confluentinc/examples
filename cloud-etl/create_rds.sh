#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

ccloud::validate_psql_installed \
  && print_pass "psql installed" \
  || exit 1

ccloud::validate_aws_cli_installed_rds_db_ready() {
  STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].DBInstanceStatus")
  if [[ "$STATUS" == "available" ]]; then
    return 0
  fi
  return 1
}

#################################################################
# Source: create and populate AWS RDS database
#################################################################
echo "Creating AWS RDS PostgreSQL database"
aws rds create-db-instance \
    --db-name $DB_INSTANCE_IDENTIFIER \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --engine postgres \
    --allocated-storage 20 \
    --db-instance-class db.t2.micro \
    --master-username pg \
    --master-user-password pg12345678 \
    --license-model postgresql-license \
    --region $RDS_REGION \
    --profile $AWS_PROFILE > /dev/null
status=$?
if [[ "$status" != 0 ]]; then
  echo "WARNING: Could not create database, troubleshoot and try again"
fi

MAX_WAIT=1200
echo
echo "Waiting up to $MAX_WAIT seconds for AWS RDS PostgreSQL database $DB_INSTANCE_IDENTIFIER to be available"
retry $MAX_WAIT ccloud::validate_aws_cli_installed_rds_db_ready $DB_INSTANCE_IDENTIFIER || exit 1
print_pass "Database $DB_INSTANCE_IDENTIFIER is available"

SECURITY_GROUP=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId")
echo "aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all --profile $AWS_PROFILE"
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all --profile $AWS_PROFILE
status=$?
if [[ "$status" != 0 ]]; then
  echo "WARNING: status response not 0 when running aws ec2 authorize-security-group-ingress"
fi
echo "aws ec2 authorize-security-group-egress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all --profile $AWS_PROFILE"
aws ec2 authorize-security-group-egress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all --profile $AWS_PROFILE
status=$?
if [[ "$status" != 0 ]]; then
  echo "WARNING: status response not 0 when running aws ec2 authorize-security-group-ingress"
fi

echo "Creating $KAFKA_TOPIC_NAME_IN.sql"
rm -fr $KAFKA_TOPIC_NAME_IN.sql
for row in $(jq -r '.[] .Data' $KAFKA_TOPIC_NAME_IN.json); do
  read -r eventSourceIP eventAction result eventDuration <<<"$(echo "$row" | jq -r '"\(.eventSourceIP) \(.eventAction) \(.result) \(.eventDuration)"')"
  echo -e "$eventSourceIP\t$eventAction\t$result\t$eventDuration" >> $KAFKA_TOPIC_NAME_IN.sql
done

echo "Create table $KAFKA_TOPIC_NAME_IN"
export CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Address")
export CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Port")
PGPASSWORD=pg12345678 psql \
   --host $CONNECTION_HOST \
   --port $CONNECTION_PORT \
   --username pg \
   --dbname $DB_INSTANCE_IDENTIFIER \
   --command "CREATE TABLE $KAFKA_TOPIC_NAME_IN (timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, eventSourceIP VARCHAR(255), eventAction VARCHAR(255), result VARCHAR(255), eventDuration BIGINT);"

./add_entries_rds.sh

print_pass "AWS RDS database ready"

exit 0
