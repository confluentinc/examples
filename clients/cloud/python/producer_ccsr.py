#!/usr/bin/env python
#
# Copyright 2020 Confluent Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# =============================================================================
#
# Produce messages to Confluent Cloud
# Using Confluent Python Client for Apache Kafka
# Writes Avro data, integration with Confluent Cloud Schema Registry
#
# =============================================================================
from confluent_kafka import SerializingProducer
from confluent_kafka.serialization import StringSerializer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer

import json
import ccloud_lib

if __name__ == '__main__':

    # Read arguments and configurations and initialize
    args = ccloud_lib.parse_args()
    config_file = args.config_file
    topic = args.topic
    conf = ccloud_lib.read_ccloud_config(config_file)

    # Create topic if needed
    ccloud_lib.create_topic(conf, topic)

    # for full list of configurations, see:
    #  https://docs.confluent.io/platform/current/clients/confluent-kafka-python/#schemaregistryclient
    schema_registry_conf = {
        'url': conf['schema.registry.url'],
        'basic.auth.user.info': conf['basic.auth.user.info']}

    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    name_avro_serializer = AvroSerializer(schema_registry_client = schema_registry_client,
                                          schema_str = ccloud_lib.name_schema,
                                          to_dict = ccloud_lib.Name.name_to_dict)
    count_avro_serializer = AvroSerializer(schema_registry_client = schema_registry_client,
                                           schema_str =  ccloud_lib.count_schema,
                                           to_dict = ccloud_lib.Count.count_to_dict)

    # for full list of configurations, see:
    #  https://docs.confluent.io/platform/current/clients/confluent-kafka-python/#serializingproducer
    producer_conf = ccloud_lib.pop_schema_registry_params_from_config(conf)
    producer_conf['key.serializer'] = name_avro_serializer
    producer_conf['value.serializer'] = count_avro_serializer
    producer = SerializingProducer(producer_conf)

    delivered_records = 0

    # Optional per-message on_delivery handler (triggered by poll() or flush())
    # when a message has been successfully delivered or
    # permanently failed delivery (after retries).
    def acked(err, msg):
        global delivered_records
        """Delivery report handler called on
        successful or failed delivery of message
        """
        if err is not None:
            print("Failed to deliver message: {}".format(err))
        else:
            delivered_records += 1
            print("Produced record to topic {} partition [{}] @ offset {}"
                  .format(msg.topic(), msg.partition(), msg.offset()))

    for n in range(10):
        name_object = ccloud_lib.Name()
        name_object.name = "alice"
        count_object = ccloud_lib.Count()
        count_object.count = n
        print("Producing Avro record: {}\t{}".format(name_object.name, count_object.count))
        producer.produce(topic=topic, key=name_object, value=count_object, on_delivery=acked)
        producer.poll(0)

    producer.flush()

    print("{} messages were produced to topic {}!".format(delivered_records, topic))

