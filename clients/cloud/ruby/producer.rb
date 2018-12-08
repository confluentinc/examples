#!/usr/bin/ruby
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
rescue Kafka::Error => e
  puts "Failed to create topic: #{e.message}"
end

0.upto(9).each do |n|
  record_key = 'alice'
  record_value = JSON.dump(count: n)
  record = "#{record_key}\t#{record_value}"
  puts "Producing record: #{record}"

  begin
    ccloud.kafka.deliver_message(record_value, key: record_key, topic: topic)
  rescue Kafka::Error => e
    puts "Failed to produce record #{record}: #{e.message}"
  end
end

puts "10 messages were successfully produced to topic #{topic}!"
