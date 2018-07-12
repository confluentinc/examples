curl -i -X POST \
    -H "Accept:application/json" \
    -H  "Content-Type:application/json" \
    http://connect-debezium:8083/connectors/ -d '
    {
        "name": "pg-source-raw",
        "config": {
            "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
            "tasks.max": "1",
            "database.hostname": "postgres",
            "database.port": "5432",
            "database.user": "postgres",
            "database.password": "postgres",
            "database.dbname" : "postgres",
            "database.server.name": "asgard",
            "database.history.kafka.bootstrap.servers": "kafka:29092",
            "database.history.kafka.topic": "schema-changes.pg-raw",
            "transforms": "addTopicSuffix",
            "transforms.addTopicSuffix.type":"org.apache.kafka.connect.transforms.RegexRouter",
            "transforms.addTopicSuffix.regex":"(.*)",
            "transforms.addTopicSuffix.replacement":"$1-raw"
        }
    }'
