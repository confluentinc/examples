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
# Consume messages from Confluent Cloud
# Using Confluent Python Client for Apache Kafka
# Reads Avro data, integration with Confluent Cloud Schema Registry
#
# =============================================================================

from confluent_kafka import DeserializingConsumer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroDeserializer
from confluent_kafka.serialization import StringDeserializer

import json
import ccloud_lib


if __name__ == '__main__':

    # Read arguments and configurations and initialize
    args = ccloud_lib.parse_args()
    config_file = args.config_file
    topic = args.topic
    conf = ccloud_lib.read_ccloud_config(config_file)

    schema_registry_conf = {
        'url': conf['schema.registry.url'],
        'basic.auth.user.info': conf['basic.auth.user.info']}
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    name_avro_deserializer = AvroDeserializer(ccloud_lib.name_schema,
                                              schema_registry_client,
                                              ccloud_lib.Name.dict_to_name)
    count_avro_deserializer = AvroDeserializer(ccloud_lib.count_schema,
                                               schema_registry_client,
                                               ccloud_lib.Count.dict_to_count)

    # for full list of configurations, see:
    #   https://docs.confluent.io/platform/current/clients/confluent-kafka-python/#deserializingconsumer
    consumer_conf = ccloud_lib.pop_schema_registry_params_from_config(conf)
    consumer_conf['key.deserializer'] = name_avro_deserializer
    consumer_conf['value.deserializer'] = count_avro_deserializer
    consumer_conf['group.id'] = 'python_example_group_2'
    consumer_conf['auto.offset.reset'] = 'earliest'
    consumer = DeserializingConsumer(consumer_conf)

    # Subscribe to topic
    consumer.subscribe([topic])

    # Process messages
    total_count = 0
    while True:
        try:
            msg = consumer.poll(1.0)
            if msg is None:
                # No message available within timeout.
                # Initial message consumption may take up to
                # `session.timeout.ms` for the consumer group to
                # rebalance and start consuming
                print("Waiting for message or event/error in poll()")
                continue
            elif msg.error():
                print('error: {}'.format(msg.error()))
            else:
                name_object = msg.key()
                count_object = msg.value()
                count = count_object.count
                total_count += count
                print("Consumed record with key {} and value {}, \
                      and updated total count to {}"
                      .format(name_object.name, count, total_count))
        except KeyboardInterrupt:
            break
        except SerializerError as e:
            # Report malformed record, discard results, continue polling
            print("Message deserialization failed {}".format(e))
            pass

    # Leave group and commit final offsets
    consumer.close()

