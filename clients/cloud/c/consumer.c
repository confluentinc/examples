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


#include <stdio.h>
#include <string.h>

#include <librdkafka/rdkafka.h>

#include "common.h"
#include "json.h"


struct user {
        char *name;
        int sum;
};

/* Only track the first 4 users seen, for keeping the example simple. */
#define TRACK_USER_CNT 4
static struct user users[TRACK_USER_CNT];

static struct user *find_user (const char *name, size_t namelen) {
        int i;

        for (i = 0 ; i < TRACK_USER_CNT ; i++) {
                if (!users[i].name) {
                        /* Free slot, populate */
                        users[i].name = strndup(name, namelen);
                        users[i].sum = 0;
                        return &users[i];
                } else if (!strncmp(users[i].name, name, namelen))
                        return &users[i];
        }

        return NULL; /* No free slots */
}


/**
 * @brief Handle a JSON-formatted message and update our counter state
 *        for the user specified in the message key.
 *
 * @returns 0 on success or -1 on parse error (non-fatal).
 */
static int handle_message (rd_kafka_message_t *rkm) {
        json_value *obj;
        static char errstr[json_error_max];
        json_settings settings = { .max_memory = 100000 };
        const char *expected_user = "alice";
        struct user *user;
        int i;

        if (!rkm->key)
                return 0;

        if (!(user = find_user(rkm->key, rkm->key_len)))
                return 0;

        if (rkm->key_len != strlen(expected_user) ||
            strncmp(rkm->key, expected_user, rkm->key_len))
                return 0;

        /* Value: expected a json object: { "count": 3 } */
        obj = json_parse_ex(&settings, rkm->payload, rkm->len, errstr);
        if (!obj) {
                fprintf(stderr, "Failed to parse JSON: %s\n", errstr);
                return -1;
        }

        if (obj->type != json_object) {
                fprintf(stderr, "Expected JSON object\n");
                json_value_free(obj);
                return -1;
        }

        for (i = 0 ; i < obj->u.object.length ; i++) {
                const json_object_entry *v = &obj->u.object.values[i];

                if (strcmp(v->name, "count") ||
                    v->value->type != json_integer)
                        continue;

                user->sum += v->value->u.integer;
                printf("User %s sum %d\n", user->name, user->sum);
                break;
        }

        json_value_free(obj);

        return 0;
}


/**
 * @brief Start and run consumer, assuming ownership of \p conf
 *
 * @returns 0 on success or -1 on error.
 */
static int run_consumer (const char *topic, rd_kafka_conf_t *conf) {
        rd_kafka_t *rk;
        char errstr[512];
        rd_kafka_resp_err_t err;
        rd_kafka_topic_partition_list_t *topics;
        int i;

        rd_kafka_conf_set(conf, "group.id", "cloud-example-c", NULL, 0);

        /* If there is no committed offset for this group, start reading
         * partitions from the beginning. */
        rd_kafka_conf_set(conf, "auto.offset.reset", "earliest", NULL, 0);

        /* Disable ERR__PARTITION_EOF when reaching end of partition. */
        rd_kafka_conf_set(conf, "enable.partition.eof", "false", NULL, 0);


        /* Create consumer.
         * A successful call assumes ownership of \p conf. */
        rk = rd_kafka_new(RD_KAFKA_CONSUMER, conf, errstr, sizeof(errstr));
        if (!rk) {
                fprintf(stderr, "Failed to create consumer: %s\n", errstr);
                rd_kafka_conf_destroy(conf);
                return -1;
        }

        /* Redirect all (present and future) partition message queues to the
         * main consumer queue so that they can all be consumed from the
         * same consumer_poll() call. */
        rd_kafka_poll_set_consumer(rk);

        /* Create subscription list.
         * The partition will be ignored by subscribe() */
        topics = rd_kafka_topic_partition_list_new(1);
        rd_kafka_topic_partition_list_add(topics, topic,
                                          RD_KAFKA_PARTITION_UA);

        /* Subscribe to topic(s) */
        fprintf(stderr,
                "Subscribed to %s, waiting for assignment and messages...\n"
                "Press Ctrl-C to exit.\n", topic);
        err = rd_kafka_subscribe(rk, topics);
        rd_kafka_topic_partition_list_destroy(topics);

        if (err) {
                fprintf(stderr, "Subscribe(%s) failed: %s\n",
                        topic, rd_kafka_err2str(err));
                rd_kafka_destroy(rk);
                return -1;
        }


        /* Consume messages */
        while (run) {
                rd_kafka_message_t *rkm;

                /* Poll for a single message or an error event.
                 * Use a finite timeout so that Ctrl-C (run==0) is honoured. */
                rkm = rd_kafka_consumer_poll(rk, 1000);
                if (!rkm)
                        continue;

                if (rkm->err) {
                        /* Consumer error: typically just informational. */
                        fprintf(stderr, "Consumer error: %s\n",
                                rd_kafka_message_errstr(rkm));
                } else {
                        /* Proper message */
                        fprintf(stderr,
                                "Received message on %s [%d] "
                                "at offset %"PRId64": %.*s\n",
                                rd_kafka_topic_name(rkm->rkt),
                                (int)rkm->partition, rkm->offset,
                                (int)rkm->len, (const char *)rkm->payload);
                        handle_message(rkm);
                }

                rd_kafka_message_destroy(rkm);
        }

        /* Close the consumer to have it gracefully leave the consumer group
         * and commit final offsets. */
        rd_kafka_consumer_close(rk);

        /* Destroy the consumer instance. */
        rd_kafka_destroy(rk);

        for (i = 0 ; i < TRACK_USER_CNT ; i++)
                if (users[i].name)
                        free(users[i].name);

        return 0;
}



int main (int argc, char **argv) {
        const char *topic;
        const char *config_file;
        rd_kafka_conf_t *conf;

        if (argc != 3) {
                fprintf(stderr, "Usage: %s <topic> <config-file>\n", argv[0]);
                exit(1);
        }

        topic = argv[1];
        config_file = argv[2];

        if (!(conf = read_config(config_file)))
                return 1;

        if (run_consumer(topic, conf) == -1)
                return 1;

        return 0;
}
