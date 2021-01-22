#!/bin/bash
source /tmp/helper.sh

echo -e "\nWaiting for ksqlDB to be RUNNING prior to executing ksqlDB statements\n"
retry 300 check_ksqlDB_host_running || exit 1

echo -e "\nksqlDB host is running, now check that necessary topics have been created"
array=("customers" "orders")
retry 200 check_schema_registry_topics_exists "${array[@]}" || exit 1

# Create KSQL queries
echo -e "\nNecessary topics have been created, now run ksqlDB statements"
ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF
