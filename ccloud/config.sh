# File with Confluent Cloud configuration parameters
# Template file at ~/.ccloud/config
#   $ cat ~/.ccloud/config
#   bootstrap.servers=<BROKER ENDPOINT>
#   ssl.endpoint.identification.algorithm=https
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
export CONFIG_FILE=~/.ccloud/config

# Set to true if you have enabled Confluent Cloud Schema Registry
# and added the appropriate configurations to your ~/.ccloud/config file
# https://docs.confluent.io/current/quickstart/cloud-quickstart.html#step-3-configure-sr-ccloud
export USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY=false

# Set to true if you have enabled Confluent Cloud KSQL
export USE_CONFLUENT_CLOUD_KSQL=false
