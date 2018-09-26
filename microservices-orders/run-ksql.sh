#!/bin/bash

# Create KSQL queries
ksql http://ksql-server:8088 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
