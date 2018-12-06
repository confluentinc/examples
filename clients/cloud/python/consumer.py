#!/usr/bin/env python
#
# Copyright 2018 Confluent Inc.
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
#
# =============================================================================

from confluent_kafka import Consumer, KafkaError
import sys
import uuid
import json


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.stderr.write('Usage: %s <path to Confluent Cloud configuration file> <topic name>\n' % sys.argv[0])
        sys.exit(1)

    # Read Confluent Cloud configuration for librdkafka clients
    config_file = sys.argv[1]
    conf = {}
    with open(config_file) as fh:
      for line in fh:
        line = line.strip()
        if line[0] != "#" and len(line) != 0:
          parameter, value = line.strip().split('=', 1)
          conf[parameter] = value.strip()

    # Create Consumer instance
    c = Consumer({
        'bootstrap.servers': conf['bootstrap.servers'],
        'broker.version.fallback': '0.10.0.0',
        'api.version.fallback.ms': 0,
        'sasl.mechanisms': 'PLAIN',
        'security.protocol': 'SASL_SSL',
        'sasl.username': conf['sasl.username'],
        'sasl.password': conf['sasl.password'],
        'group.id': str(uuid.uuid1()),  # this will create a new consumer group on each invocation.
        'auto.offset.reset': 'earliest'
    })

    # Subscribe to topic
    topic = sys.argv[2]
    c.subscribe([topic])

    total_count=0
    try:
        while True:
            msg = c.poll(1.0)  # Wait for message or event/error
            if msg is None:
                # No message available within timeout.
                # Initial message consumption may take up to `session.timeout.ms` for
                #   the group to rebalance and start consuming
                continue
            elif not msg.error():
                # Check for Kafka message
                record_key = msg.key()
                record_value = msg.value()
                data = json.loads(record_value)
                count = data['count']
                total_count += count
                print ("Consumed record with key {} and value {}, and updated total count to {}".format(record_key,record_value,total_count))
            else:
                if msg.error().code() != KafkaError._PARTITION_EOF:
                  print('error: {}'.format(msg.error()))
    except KeyboardInterrupt:
        pass
    finally:
        # Leave group and commit final offsets
        c.close()

