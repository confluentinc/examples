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
#include <fcntl.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <assert.h>
#include <signal.h>

#include <librdkafka/rdkafka.h>

#include "common.h"

int run = 1;

/* Signal handler for SIGINT */
static void handle_ctrlc (int sig) {
        fprintf(stderr, "Terminating\n");
        run = 0;
}


/**
 * @brief Read key=value client configuration file from \p config_file,
 *        returning a populated config object on success, or NULL on error.
 */
rd_kafka_conf_t *read_config (const char *config_file) {
        FILE *fp;
        rd_kafka_conf_t *conf;
        char errstr[256];
        char buf[1024];
        int line = 0;

        if (!(fp = fopen(config_file, "r"))) {
                fprintf(stderr, "Failed to open %s: %s\n",
                        config_file, strerror(errno));
                return NULL;
        }

        conf = rd_kafka_conf_new();
        /* Read configuration file, line by line. */
        while (fgets(buf, sizeof(buf), fp)) {
                char *s = buf;
                char *t;
                char *key, *value;
                char errstr[256];

                line++;

                /* Left-trim */
                while (isspace(*s))
                        s++;

                /* Right-trim */
                t = s + strlen(s) - 1;
                while (t >= s && isspace(*t))
                        t--;
                *(t+1) = '\0';

                /* Ignore empty and comment lines */
                if (!*s || *s == '#')
                        continue;

                /* Expected format: "key=value".
                 * Find "=" and split line up into key and value. */
                if (!(t = strchr(s, '=')) || t == s) {
                        fprintf(stderr,
                                "%s:%d: invalid syntax: expected key=value\n",
                                config_file, line);
                        rd_kafka_conf_destroy(conf);
                        return NULL;
                }

                key = s;
                *t = '\0';
                value = t+1;

                /* Set configuration value in config object. */
                if (rd_kafka_conf_set(conf, key, value,
                                      errstr, sizeof(errstr)) !=
                    RD_KAFKA_CONF_OK) {
                        fprintf(stderr,
                                "%s: %d: %s\n", config_file, line, errstr);
                        rd_kafka_conf_destroy(conf);
                        return NULL;
                }
        }
        fclose(fp);

        /* Set up signal handlers for termination */
        signal(SIGINT, handle_ctrlc);
        signal(SIGTERM, handle_ctrlc);

        return conf;
}



/**
 * @brief Create topic using Admin API of an existing client instance.
 *
 * @returns 0 on success or -1 on error.
 */
int create_topic (rd_kafka_t *rk, const char *topic,
                  int num_partitions) {
        rd_kafka_NewTopic_t *newt;
        char errstr[256];
        rd_kafka_queue_t *queue;
        rd_kafka_event_t *rkev;
        const rd_kafka_CreateTopics_result_t *res;
        const rd_kafka_topic_result_t **restopics;
        const int replication_factor_or_use_default = -1;
        size_t restopic_cnt;
        int ret = 0;

        fprintf(stderr, "Creating topic %s\n", topic);

        newt = rd_kafka_NewTopic_new(topic, num_partitions, replication_factor_or_use_default,
                                     errstr, sizeof(errstr));
        if (!newt) {
                fprintf(stderr, "Failed to create NewTopic object: %s\n",
                        errstr);
                return -1;
        }

        /* Use a temporary queue for the asynchronous Admin result */
        queue = rd_kafka_queue_new(rk);

        /* Asynchronously create topic, result will be available on \c queue */
        rd_kafka_CreateTopics(rk, &newt, 1, NULL, queue);

        rd_kafka_NewTopic_destroy(newt);

        /* Wait for result event */
        rkev = rd_kafka_queue_poll(queue, 15*1000);
        if (!rkev) {
                /* There will eventually be a result, after operation
                 * and request timeouts, but in this example we'll only
                 * wait 15s to avoid stalling too long when cluster
                 * is not available. */
                fprintf(stderr, "No create topics result in 15s\n");
                return -1;
        }

        if (rd_kafka_event_error(rkev)) {
                /* Request-level failure */
                fprintf(stderr, "Create topics request failed: %s\n",
                        rd_kafka_event_error_string(rkev));
                rd_kafka_event_destroy(rkev);
                return -1;
        }

        /* Extract the result type from the event. */
        res = rd_kafka_event_CreateTopics_result(rkev);
        assert(res); /* Since we're using a dedicated queue we know this is
                      * a CreateTopics result type. */

        /* Extract the per-topic results from the result type. */
        restopics = rd_kafka_CreateTopics_result_topics(res, &restopic_cnt);
        assert(restopics && restopic_cnt == 1);

        if (rd_kafka_topic_result_error(restopics[0]) ==
            RD_KAFKA_RESP_ERR_TOPIC_ALREADY_EXISTS) {
                fprintf(stderr, "Topic %s already exists\n",
                        rd_kafka_topic_result_name(restopics[0]));
        } else if (rd_kafka_topic_result_error(restopics[0])) {
                fprintf(stderr, "Failed to create topic %s: %s\n",
                        rd_kafka_topic_result_name(restopics[0]),
                        rd_kafka_topic_result_error_string(restopics[0]));
                ret = -1;
        } else {
                fprintf(stderr, "Topic %s successfully created\n",
                        rd_kafka_topic_result_name(restopics[0]));
        }

        rd_kafka_event_destroy(rkev);

        return ret;
}
