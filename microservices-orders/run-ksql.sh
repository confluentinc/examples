#!/bin/bash

echo "Sleeping 150 seconds until KSQL server is up and topics have data"
sleep 150

# Create KSQL queries
ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF
