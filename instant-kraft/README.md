# Instant KRaft Demo
Let's make some delicious instant KRaft
          ___
        .'O o'-._
       / O o_.-`|
      /O_.-'  O |
      |O o O .-`
      |o O_.-'
      '--`

## Step 1
```
$ git clone https://github.com/confluentinc/examples.git && cd examples/instant-kraft

$ docker compose up
```

That's it! One container, one process, doing the the broker and controller work. No Zookeeper.
The key server configure to enable KRaft is the `process.roles`. Here we have the same node doing both the broker and quorum conroller work. Note that this is ok for local development, but in production you should have seperate nodes for the broker and controller quorum nodes.

```
KAFKA_PROCESS_ROLES: 'broker,controller'
```

## Step 2
Start streaming

```
$ docker compose exec broker kafka-topics --create --topic zookeeper-vacation-ideas --bootstrap-server localhost:9092

$ docker-compose exec broker kafka-producer-perf-test --topic zookeeper-vacation-ideas \
    --num-records 200000 \
    --record-size 50 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=localhost:9092 \
        compression.type=none \
        batch.size=8196
```

## Step 3
Explore the cluster using the new kafka metadata command line tool.

```
 $ docker-compose exec broker kafka-metadata-shell --snapshot /tmp/kraft-combined-logs/__cluster_metadata-0/00000000000000000000.log

# use the metadata shell to explore the quorum
>> ls metadataQuorum

>> cat metadataQuorum/leader
```

Note: the `update_run.sh` is to get around some checks in the cp-kafka docker image. There are plans to change those checks in the future.

The scipt also formats the storage volumes with a random uuid for the cluster. Formatting kafka storage is very important in production environments. See the AK documentation for more information.