#!/bin/bash

echo -e "\nWaiting for ksqlDB and topics to be available prior to running ksqlDB statements\n"
while [[ $(curl -s http://ksqldb-server:8088/info) != *RUNNING* \
             ||  $(curl -s http://schema-registry:8081/subjects) != *customers* \
             ||  $(curl -s http://schema-registry:8081/subjects) != *orders* ]]
do 
    sleep 5
    echo "Sleeping for 5 seconds, waiting for ksqlDB and topics to be available"
done


# Create KSQL queries
ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF
