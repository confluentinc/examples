package ccloud_lib

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
    "os"
    "flag"
    "bufio"
    "strings"
    "fmt"
)

type RecordValue struct {
    Count   int
}

func ParseArgs() (*string, *string) {

    config_file := flag.String("f", "", "path to Confluent Cloud configuration file")
    topic := flag.String("t", "", "topic name")
    flag.Parse()
    if *config_file == "" || *topic == "" {
        flag.Usage()
        os.Exit(2) // the same exit code flag.Parse uses
    }

    return config_file, topic

}


func ReadCCloudConfig(config_file string) (map[string]string) {

    m := make(map[string]string)

    file, err := os.Open(config_file)
    if err != nil {
        fmt.Printf("Failed to open file: %s", err)
        os.Exit(1)
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        line := scanner.Text()
        if !strings.HasPrefix(line, "#") && len(line) != 0 {
            foo := strings.Split(line, "=")
            parameter := strings.TrimSpace(foo[0])
            value := strings.TrimSpace(foo[1])
            m[parameter] = value
        }
    }

    if err := scanner.Err(); err != nil {
        fmt.Printf("Failed to read file: %s", err)
        os.Exit(1)
    }

    return m

}

