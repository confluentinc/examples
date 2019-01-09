// =============================================================================
//
// Produce messages to Confluent Cloud
// Using Confluent Golang Client for Apache Kafka
//
// =============================================================================


package main

/**
 * Copyright 2018 Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import (
    "./ccloud_lib"
    "github.com/confluentinc/confluent-kafka-go/kafka"
    "os"
    "fmt"
    "context"
    "time"
    "encoding/json"
)

func main() {

    // Initialization
    config_file, topic := ccloud_lib.ParseArgs()
    conf := ccloud_lib.ReadCCloudConfig(*config_file)

    // Create Producer instance
    p, err := kafka.NewProducer(&kafka.ConfigMap{
	"bootstrap.servers":       conf["bootstrap.servers"],
	"sasl.mechanisms":         "PLAIN",
	"security.protocol":       "SASL_SSL",
	"sasl.username":           conf["sasl.username"],
	"sasl.password":           conf["sasl.password"]})
    if err != nil {
       fmt.Printf("Failed to create producer: %s", err)
       os.Exit(1)
    }

    // Create topic if needed
    a, err := kafka.NewAdminClientFromProducer(p)
    if err != nil {
        fmt.Printf("Failed to create new admin client from producer: %s", err)
        os.Exit(1)
    }
    // Contexts are used to abort or limit the amount of time
    // the Admin call blocks waiting for a result.
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    // Create topics on cluster.
    // Set Admin options to wait up to 60s for the operation to finish
    maxDur, err := time.ParseDuration("60s")
    if err != nil {
        fmt.Printf("ParseDuration(60s): %s", err)
        os.Exit(1)
    }
    results, err := a.CreateTopics(
	ctx,
	// Multiple topics can be created simultaneously
	// by providing more TopicSpecification structs here.
	[]kafka.TopicSpecification{{
		Topic:             *topic,
		NumPartitions:     1,
		ReplicationFactor: 3}},
	// Admin options
	kafka.SetAdminOperationTimeout(maxDur))
    if err != nil {
	fmt.Printf("Failed to create topic: %v\n", err)
	os.Exit(1)
    }
    for _, result := range results {
        fmt.Printf("%s\n", result)
    }
    a.Close()

    // Optional per-message on_delivery handler (triggered by Poll() or Flush())
    go func() {
        for e := range p.Events() {
	    switch ev := e.(type) {
		case *kafka.Message:
		    if ev.TopicPartition.Error != nil {
                        fmt.Printf("Failed to deliver message: %v\n", ev.TopicPartition)
	    	    } else {
                        fmt.Printf("Successfully produced record to topic %s partition [%d] @ offset %v\n",
                            *ev.TopicPartition.Topic, ev.TopicPartition.Partition, ev.TopicPartition.Offset)
	   	    }
	    }
         }
    }()

    for n := 0; n < 10; n++ {
        record_key := "alice"
        record_value, _ := json.Marshal(map[string]int{"count": n})
        fmt.Printf("Preparing to produce record: %s\t%s\n", record_key, record_value)
	p.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: topic, Partition: kafka.PartitionAny},
                Key:            []byte(record_key),
		Value:          []byte(record_value),
	}, nil)
    }

    p.Flush(15 * 1000)

    fmt.Printf("10 messages were produced to topic %s!", *topic)

}


