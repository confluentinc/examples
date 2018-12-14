#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.0 || exit 
check_running_elasticsearch 5.6.5 || exit 1
check_running_grafana 5.0.3 || exit 1

./stop.sh

cp -nR ksql/ksql-clickstream-demo/demo/connect-config/null-filter-4.0.0-SNAPSHOT.jar $CONFLUENT_HOME/share/java/kafka-connect-elasticsearch/.
confluent start

./start_datagen.sh

ksql http://localhost:8088 <<EOF
run script './ksql/ksql-clickstream-demo/demo/clickstream-schema.sql';
exit ;
EOF

(cd ksql/ksql-clickstream-demo/demo/ && ./ksql-tables-to-grafana.sh &>/dev/null)
(cd ksql/ksql-clickstream-demo/demo/ && ./elastic-dynamic-template.sh &>/dev/null)
(cd ksql/ksql-clickstream-demo/demo/ && ./clickstream-analysis-dashboard.sh &>/dev/null)

echo -e "\n-> Navigate to the Grafana dashboard at http://localhost:3000/dashboard/db/click-stream-analysis.\n\nLogin with user ID admin and password admin.\n\n"