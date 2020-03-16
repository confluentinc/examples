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
use futures::future::Future;
use rdkafka::error::KafkaError;
use rdkafka::message::OwnedMessage;
use rdkafka::producer::{FutureProducer, FutureRecord};
use std::boxed::Box;

mod utils;

fn log_produce_result(
    topic: &str,
    result: Result<(i32, i64), (KafkaError, OwnedMessage)>,
) -> Result<(), ()> {
    result
        .and_then(|(p, o)| {
            println!(
                "Successfully produced record to topic {} partition [{}] @ offset {}",
                topic, p, o
            );
            Ok(())
        })
        .map_err(|(err, _)| eprintln!("kafka error: {}", err))
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let (topic, config) = utils::get_config()?;
    let producer: FutureProducer = config.create()?;

    let messages = (0..9)
        .map(|msg| {
            let value = msg.to_string();
            println!("Preparing to produce record: {} {}", "alice", value);
            producer.send(
                FutureRecord::to(&topic)
                    .payload(value.as_bytes())
                    .key("alice"),
                0,
            )
        })
        .collect::<Vec<_>>();

    for msg in messages {
        msg.wait()
            .map_err(|err| eprintln!("error producing message: {}", err))
            .and_then(|result| log_produce_result(&topic, result))
            .ok();
    }

    Ok(())
}
