#!/bin/bash

echo "Sleeping 90 seconds until KSQL server is up"
sleep 90

# Create KSQL queries
ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
