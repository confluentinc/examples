#!/usr/bin/ruby
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
# Using the ZenDesk Ruby Client for Apache Kafka (https://github.com/zendesk/ruby-kafka)
#
# =============================================================================

require 'json'
require './c_cloud'

ccloud = CCloud.new
topic = ccloud.topic
begin
  ccloud.kafka.create_topic(topic, num_partitions: 1, replication_factor: 3)
  puts "Created topic #{topic}"
rescue Kafka::TopicAlreadyExists => e
  puts "Did not create topic #{topic} because it already exists."
end

produced_messages = 0
begin
  0.upto(9).each do |n|
    record_key = 'alice'
    record_value = JSON.dump(count: n)
    record = "#{record_key}\t#{record_value}"
    puts "Producing record: #{record}"

    begin
      ccloud.producer.produce(record_value, key: record_key, topic: topic)
      produced_messages += 1
    rescue Kafka::Error => e
      puts "Failed to produce record #{record}: #{e.message}"
    end
  end
ensure
  # deliver all the buffered messages
  ccloud.producer.deliver_messages
  # Make sure to call `#shutdown` on the producer in order to avoid leaking
  # resources. `#shutdown` will wait for any pending messages to be delivered
  # before returning.
  ccloud.producer.shutdown
end
puts "#{produced_messages} messages were successfully produced to topic #{topic}!"
