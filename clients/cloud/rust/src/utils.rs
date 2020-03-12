/**
 * Copyright 2020 Confluent Inc.
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
use clap::{App, Arg};
use rdkafka::config::ClientConfig;
use std::boxed::Box;
use std::fs::File;
use std::io::BufRead;
use std::io::BufReader;

pub fn get_config() -> Result<(String, ClientConfig), Box<std::error::Error>> {
    let matches = App::new("rust client example")
        .version(option_env!("CARGO_PKG_VERSION").unwrap_or(""))
        .arg(
            Arg::with_name("config")
                .help("path to confluent cloud config file")
                .long("config")
                .takes_value(true)
                .required(true),
        )
        .arg(
            Arg::with_name("topic")
                .help("test topic to use")
                .long("topic")
                .takes_value(true)
                .required(true),
        )
        .get_matches();

    let mut kafka_config = ClientConfig::new();

    let file = File::open(matches.value_of("config").ok_or("error parsing config")?)?;
    for line in BufReader::new(&file).lines() {
        let cur_line: String = line?.trim().to_string();
        if cur_line.starts_with('#') || cur_line.len() < 1 {
            continue;
        }
        let key_value: Vec<&str> = cur_line.split("=").collect();
        kafka_config.set(
            key_value.get(0).ok_or("malformed key")?,
            key_value.get(1).ok_or("malformed value")?,
        );
    }

    Ok((
        matches
            .value_of("topic")
            .ok_or("error parsing topic")?
            .to_string(),
        kafka_config,
    ))
}
