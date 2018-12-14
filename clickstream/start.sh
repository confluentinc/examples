#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.1 || exit 
check_running_elasticsearch 5.6.5 || exit 1
check_running_grafana 5.0.3 || exit 1

./stop.sh

cp -nR ksql/ksql-clickstream-demo/demo/connect-config/null-filter-4.0.0-SNAPSHOT.jar $CONFLUENT_HOME/share/java/kafka-connect-elasticsearch/.
confluent start

if is_ce; then PROPERTIES=" propertiesFile=$CONFLUENT_HOME/etc/ksql/datagen.properties"; else PROPERTIES=""; fi
ksql-datagen -daemon quickstart=clickstream format=json topic=clickstream maxInterval=100 iterations=500000 $PROPERTIES &>/dev/null &
ksql-datagen quickstart=clickstream_codes format=json topic=clickstream_codes maxInterval=20 iterations=100 $PROPERTIES &>/dev/null &
ksql-datagen quickstart=clickstream_users format=json topic=clickstream_users maxInterval=10 iterations=1000 $PROPERTIES &>/dev/null &
sleep 5

ksql http://localhost:8088 <<EOF
run script './ksql/ksql-clickstream-demo/demo/clickstream-schema.sql';
exit ;
EOF

(cd ksql/ksql-clickstream-demo/demo/ && ./ksql-tables-to-grafana.sh &>/dev/null)
(cd ksql/ksql-clickstream-demo/demo/ && ./elastic-dynamic-template.sh &>/dev/null)
(cd ksql/ksql-clickstream-demo/demo/ && ./clickstream-analysis-dashboard.sh &>/dev/null)

echo -e "\n-> Navigate to the Grafana dashboard at http://localhost:3000/dashboard/db/click-stream-analysis.\n\nLogin with user ID admin and password admin.\n\n"