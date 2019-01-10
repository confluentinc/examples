// =============================================================================
//
// Consume messages from Confluent Cloud
// Using Confluent Golang Client for Apache Kafka
//
// =============================================================================


package main

/**
 * Copyright 2019 Confluent Inc.
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
    "os/signal"
    "fmt"
    "encoding/json"
    "syscall"
)

type RecordValue ccloud_lib.RecordValue

func main() {

    // Initialization
    config_file, topic := ccloud_lib.ParseArgs()
    conf := ccloud_lib.ReadCCloudConfig(*config_file)

    // Create Consumer instance
    c, err := kafka.NewConsumer(&kafka.ConfigMap{
        "bootstrap.servers":  conf["bootstrap.servers"],
	"sasl.mechanisms":    "PLAIN",
	"security.protocol":  "SASL_SSL",
	"sasl.username":      conf["sasl.username"],
	"sasl.password":      conf["sasl.password"],
        "group.id":           "go_example_group_1",
        "auto.offset.reset":  "earliest"})
    if err != nil {
       fmt.Printf("Failed to create consumer: %s", err)
       os.Exit(1)
    }

    // Subscribe to topic
    err = c.SubscribeTopics([]string{*topic}, nil)
    sigchan := make(chan os.Signal, 1)
    signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

    // Process messages
    total_count := 0
    run := true
    for run == true {
        select {
            case sig := <-sigchan:
                fmt.Printf("Caught signal %v: terminating\n", sig)
                run = false
            default:
		ev := c.Poll(100)
		if ev == nil {
			continue
		}
		switch e := ev.(type) {
		case *kafka.Message:
                    record_key := string(e.Key)
                    record_value := e.Value
                    data := RecordValue{}
                    err := json.Unmarshal(record_value, &data)
	            if err != nil {
		        fmt.Println("error:", err)
	            }
                    count := data.Count
                    total_count += count
                    fmt.Printf("Consumed record with key %s and value %s, and updated total count to %d\n", record_key, record_value, total_count)
		case kafka.Error:
			// Errors should generally be considered as informational, the client will try to automatically recover
			fmt.Fprintf(os.Stderr, "%% Error: %v\n", e)
		default:
			fmt.Printf("Ignored %v\n", e)
		}
        }
    }

    fmt.Printf("Closing consumer\n")
    c.Close()

}


