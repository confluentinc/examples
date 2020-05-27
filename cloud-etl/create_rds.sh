#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_psql \
  && print_pass "psql installed" \
  || exit 1

check_aws_rds_db_ready() {
  STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].DBInstanceStatus")
  if [[ "$STATUS" == "available" ]]; then
    return 0
  fi
  return 1
}

#################################################################
# Source: create and populate AWS RDS database
#################################################################
echo "Creating AWS RDS Postgres database"
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

MAX_WAIT=1200
echo
echo "Waiting up to $MAX_WAIT seconds for AWS RDS PostgreSQL database $DB_INSTANCE_IDENTIFIER to be available"
retry $MAX_WAIT check_aws_rds_db_ready $DB_INSTANCE_IDENTIFIER || exit 1
print_pass "Database $DB_INSTANCE_IDENTIFIER is available"

SECURITY_GROUP=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId")
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all
aws ec2 authorize-security-group-egress --group-id $SECURITY_GROUP --cidr 0.0.0.0/0 --protocol all

echo "Creating eventLogs.sql"
rm -fr eventLogs.sql
timestamp="1590510745323"
for row in $(jq -r '.[] .Data' eventLogs.json); do
  read -r eventSourceIP eventAction result eventDuration <<<"$(echo "$row" | jq -r '"\(.eventSourceIP) \(.eventAction) \(.result) \(.eventDuration)"')"
  echo -e "$timestamp\t$eventSourceIP\t$eventAction\t$result\t$eventDuration" >> eventLogs.sql
done

echo "Create table eventLogs"
export CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Address")
export CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Port")
PGPASSWORD=pg12345678 psql \
   --host $CONNECTION_HOST \
   --port $CONNECTION_PORT \
   --username pg \
   --dbname $DB_INSTANCE_IDENTIFIER \
   --command "CREATE TABLE eventLogs (timestamp VARCAR(255), eventSourceIP VARCHAR(255), eventAction VARCHAR(255), result VARCHAR(255), eventDuration BIGINT);"
echo "Populate table eventLogs"
PGPASSWORD=pg12345678 psql \
   --host $CONNECTION_HOST \
   --port $CONNECTION_PORT \
   --username pg \
   --dbname $DB_INSTANCE_IDENTIFIER \
   --command "\copy eventLogs from 'eventLogs.sql';"
print_pass "AWS RDS database ready"

exit 0
