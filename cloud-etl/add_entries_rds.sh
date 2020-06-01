#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

export CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Address")
export CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Port")

# File has ~500 records, so run several times to fulfill the flush size requirement of 1000 records / partition for the sink connectors
echo -e "Adding ~11k records to table $KAFKA_TOPIC_NAME_IN\n"
for i in {1..22}; do
  PGPASSWORD=pg12345678 psql \
     --host $CONNECTION_HOST \
     --port $CONNECTION_PORT \
     --username pg \
     --dbname $DB_INSTANCE_IDENTIFIER \
     --command "\copy $KAFKA_TOPIC_NAME_IN(eventSourceIP,eventAction,result,eventDuration) from '$KAFKA_TOPIC_NAME_IN.sql';"
done
print_pass "AWS RDS database ready"

exit 0
