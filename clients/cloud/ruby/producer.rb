#!/usr/bin/ruby
#
# Copyright 2022 Confluent Inc.
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
  create_topic_handle = ccloud.admin.create_topic(topic, 1, 3)
  create_topic_handle.wait(max_wait_timeout: 15.0)
  puts "Created topic #{topic}"
rescue => e
  puts "Failed to create topic #{topic}: #{e.message}"
end

produced_messages = 0
begin
  0.upto(9).each do |n|
    record_key = 'alice'
    record_value = JSON.dump(count: n)
    record = "#{record_key}\t#{record_value}"
    puts "Producing record: #{record}"

    begin
      ccloud.producer.produce(
        topic: topic,
        payload: record_value,
        key: record_key
      )
      produced_messages += 1
    rescue => e
      puts "Failed to produce record #{record}: #{e.message}"
    end
  end
ensure
  # delivers any buffered messages and cleans up resources
  ccloud.producer.close
end
puts "#{produced_messages} messages were successfully produced to topic #{topic}!"
