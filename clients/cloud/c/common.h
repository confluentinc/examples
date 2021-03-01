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


#ifndef COMMON_H
#define COMMON_H

#if RD_KAFKA_VERSION < 0x000b0600
#error "Requires librdkafka v0.11.6 or later: see https://github.com/edenhill/librdkafka/blob/master/README.md#installing-prebuilt-packages"
#endif

extern int run;
rd_kafka_conf_t *read_config (const char *config_file);
int create_topic (rd_kafka_t *rk, const char *topic,
                  int num_partitions);

void error_cb (rd_kafka_t *rk, int err, const char *reason, void *opaque);

#endif /* COMMON_H */
