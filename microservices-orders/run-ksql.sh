#!/bin/bash

echo "Sleeping 300 seconds until ksqlDB server starts and topics have data"
sleep 300

# Create KSQL queries
ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF
