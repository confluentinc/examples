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
    //"github.com/confluentinc/confluent-kafka-go/kafka"
    //"os"
    "fmt"
)

func main() {

    config_file, topic := ccloud_lib.ParseArgs()

    conf := ccloud_lib.ReadCCloudConfig(*config_file)
    fmt.Println(conf["bootstrap.servers"])

}


