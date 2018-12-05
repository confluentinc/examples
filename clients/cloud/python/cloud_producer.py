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
# Produce messages to Confluent Cloud
# Using Confluent Python Client for Apache Kafka
#
# =============================================================================

from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic
import sys
import pprint


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.stderr.write('Usage: %s <path to Confluent Cloud configuration file> <topic name>\n' % sys.argv[0])
        sys.exit(1)

    # Read Confluent Cloud configuration for librdkafka clients
    config_file = sys.argv[1]
    conf = {}
    with open(config_file) as fh:
      for line in fh:
        if line[0] != "#" and line.strip():
          #print line
          parameter, value = line.strip().split('=', 1)
          conf[parameter] = value.strip()
    fh.close
    #pprint.pprint(conf)
    #print conf['bootstrap.servers']
    #print conf['sasl.username']
    #print conf['sasl.password']

    # Create Producer instance
    p = Producer({
           'bootstrap.servers': conf['bootstrap.servers'],
           'broker.version.fallback': '0.10.0.0',
           'api.version.fallback.ms': 0,
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': conf['sasl.username'],
           'sasl.password': conf['sasl.password']
    })

    # Topic creation
    topic = sys.argv[2]
    a = AdminClient({
           'bootstrap.servers': conf['bootstrap.servers'],
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': conf['sasl.username'],
           'sasl.password': conf['sasl.password']
    })
    fs = a.create_topics([NewTopic(topic, num_partitions=1, replication_factor=3)])

    # Wait for operation to finish.
    # Timeouts are preferably controlled by passing request_timeout=15.0
    # to the create_topics() call.
    # All futures will finish at the same time.
    for topic, f in fs.items():
        try:
            f.result()  # The result itself is None
            print("Topic {} created".format(topic))
        except Exception as e:
            print("Failed to create topic {}: {}".format(topic, e))


    # Optional per-message delivery callback (triggered by poll() or flush())
    # when a message has been successfully delivered or permanently
    # failed delivery (after retries).
    def acked(err, msg):
        """Delivery report callback called (from flush()) on successful or failed delivery of the message."""
        if err is not None:
            print("failed to deliver message: {0}".format(err.str()))
        else:
            print("produced to: {0} [{1}] @ {2}".format(msg.topic(), msg.partition(), msg.offset()))

    for n in range(100):
      p.produce(topic, "m" + `n`, callback=acked)
      p.poll(0)

    p.flush(10)

