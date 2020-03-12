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
# Consume messages from Confluent Cloud
# Using the ZenDesk Ruby Client for Apache Kafka (https://github.com/zendesk/ruby-kafka)
#
# =============================================================================

require 'json'
require './c_cloud'

ccloud = CCloud.new
topic = ccloud.topic

# subscribe to a topic with default_offset earliest
# to start reading from the beginning of the topic
# if no committed offsets exist
ccloud.consumer.subscribe(topic, default_offset: :earliest)

total_count = 0
puts "Consuming messages from #{topic}"
# Process messages
while true
  begin
    ccloud.consumer.each_message do |message|
      record_key = message.key
      record_value = message.value
      data = JSON.parse(record_value)
      count = data['count']
      total_count += count

      puts "Consumed record with key #{record_key} and value #{record_value}, " \
         "and updated total count #{total_count}"
    end
  rescue Kafka::Error => e
    puts "Consuming messages from #{topic} failed: #{e.message}"
  end
end
