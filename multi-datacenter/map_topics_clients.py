#!/usr/bin/env python2

#########################
#
# Overview
# --------
# Dynamically map which producers are writing to which topics and which consumers are reading from which topics.
# Assumes Confluent Monitoring Interceptors are running.
#
# Note: for demo purposes only, not for production. Format of monitoring data subject to change
#
# Usage
# -----
# ./map_topics_clients.py
#
# Sample output
# -------------
#
# Reading topic _confluent-monitoring for 60 seconds...please wait
# 
# EN_WIKIPEDIA_GT_1
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-84e85189-4f37-460c-991f-bb7bbb4b5a58-StreamThread-12-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-84e85189-4f37-460c-991f-bb7bbb4b5a58-StreamThread-9-producer
#   consumers
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3
# 
# EN_WIKIPEDIA_GT_1_COUNTS
#   producers
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-df19ff7e-4d42-4b40-8133-a3632c86e42d-StreamThread-13-producer
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-df19ff7e-4d42-4b40-8133-a3632c86e42d-StreamThread-14-producer
#   consumers
#     EN_WIKIPEDIA_GT_1_COUNTS-consumer
# 
# WIKIPEDIABOT
#   producers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-7d47ae21-e734-43da-9782-bae3191fc85a-StreamThread-7-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-7d47ae21-e734-43da-9782-bae3191fc85a-StreamThread-8-producer
#   consumers
#     connect-elasticsearch-ksql
# 
# WIKIPEDIANOBOT
#   producers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-6f29b3fb-abf8-4c3e-bb8d-266cb5aa65c6-StreamThread-2-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-6f29b3fb-abf8-4c3e-bb8d-266cb5aa65c6-StreamThread-3-producer
#   consumers
#     WIKIPEDIANOBOT-consumer
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-changelog
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-84e85189-4f37-460c-991f-bb7bbb4b5a58-StreamThread-12-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-84e85189-4f37-460c-991f-bb7bbb4b5a58-StreamThread-9-producer
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-repartition
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-84e85189-4f37-460c-991f-bb7bbb4b5a58-StreamThread-11-producer
#   consumers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
# 
# wikipedia.parsed
#   producers
#     connect-worker-producer
#   consumers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
#     connect-replicator
# 
# wikipedia.parsed.replica
#   producers
#     connect-worker-producer
#
#########################

import json
from collections import defaultdict
import subprocess
from threading import Timer

def get_output():
    """This function reads from the topic _confluent-monitoring
    for 60 seconds"""

    kill = lambda process: process.kill()

    # 'timeout 60' should not be required but otherwise timer never kills the process 
    command = "docker-compose exec control-center bash -c 'timeout 60 /usr/bin/control-center-console-consumer /etc/confluent-control-center/control-center.properties --topic _confluent-monitoring'"

    print "Reading topic _confluent-monitoring for 60 seconds...please wait"

    try:
        proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    except Exception as e:
        print e

    my_timer = Timer(1, kill, [proc])
    try:
        my_timer.start()
        stdout, stderr = proc.communicate()
    finally:
        my_timer.cancel()

    return stdout



topicMap = defaultdict(lambda: defaultdict(dict))

monitoringData = get_output()
for line in monitoringData.splitlines():
    
    try:
        a, b, c, d, e = line.strip().split("\t")
    except Exception as e:
        continue

    data = json.loads(e)

    topic = data["topic"]
    clientType = data["clientType"]
    clientId = data["clientId"]
    group = data["group"]

    if clientType == "PRODUCER":
        id = clientId
    else:
        id = group

    if clientType != "CONTROLCENTER":
        topicMap[topic][clientType][id] = 1


for topic in sorted(topicMap.keys()):
    print "\n" + topic + ""
    producers = sorted(topicMap[topic]["PRODUCER"])
    if len(producers) > 0:
        print "  producers"
    for p in producers:
        print "    " + p
    consumers = sorted(topicMap[topic]["CONSUMER"])
    if len(consumers) > 0:
        print "  consumers"
    for c in consumers:
        print "    " + c
