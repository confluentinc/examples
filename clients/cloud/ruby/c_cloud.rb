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
# Helper module
#
# =============================================================================

require 'optparse'
require 'kafka'

#
# Helper class for working with Confluent Cloud
#
class CCloud
  attr_reader :kafka

  def initialize
    # Parse arguments, load the CCloud config and initialize the Kafka client
    @args = parse_args!
    @config = load_config(@args[:config])
    @kafka = Kafka.new(
      seed_brokers: @config[:'bootstrap.servers'],
      sasl_plain_username: @config[:'sasl.username'],
      sasl_plain_password: @config[:'sasl.password'],
      ssl_ca_certs_from_system: true
    )
  end

  def topic
    @args[:topic]
  end

  #
  # An asynchronous producer configured for the low-throughput needs of this example
  #
  def producer
    @producer ||= @kafka.async_producer(
      # Trigger a delivery once 5 messages have been buffered.
      delivery_threshold: 5,

      # Trigger a delivery every 5 milliseconds.
      delivery_interval: 0.005,
    )
  end

  def consumer
    return @consumer unless @consumer.nil?

    # Consumers with the same group id will form a Consumer Group together.
    @consumer = @kafka.consumer(group_id: 'ruby_example_group_1')

    # It's better to shut down gracefully than to kill the process.
    at_exit do
      @consumer.stop # Leave group and commit final offsets
    end
    @consumer
  end

  private

  def parse_args!
    options = {}

    OptionParser.new do |opts|
      opts.banner = 'Ruby client example to produce and consume messages from Confluent Cloud'

      opts.on('-f', '--config CONFIG', 'path to Confluent Cloud configuration file') do |v|
        options[:config] = v
      end
      opts.on('-t', '--topic TOPIC', 'topic name') do |v|
        options[:topic] = v
      end
    end.parse!
    %i[topic config].each do |key|
      raise OptionParser::MissingArgument, "The '#{key}' argument is required!" if options[key].nil?
    end

    options
  end

  #
  # Parses the given CCloud config and returns a Hash of it
  #
  def load_config(config_file)
    conf = File.read(config_file).lines
               .map(&:strip)
               .delete_if { |l| l.empty? || l.start_with?('#') }
               .each_with_object({}) do |line, config|
      parameter, value = line.split('=', 2)
      config[parameter.to_sym] = value
      config
    end
    conf[:'bootstrap.servers'] = conf[:'bootstrap.servers'].split(',')
    conf
  end
end
