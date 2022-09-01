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
$ git clone https://github.com/confluentinc/examples.git && cd exampls/instant-kraft

$ docker compose up
```

That's it! One container, one process, doing the the broker and controller work. 
The key server configure to enable KRaft is the `process.roles`. Here we have the same node doing both the broker and quorum conroller work.
```
KAFKA_PROCESS_ROLES: 'broker,controller'
```

## Step 2
Start streaming

```
$ docker compose exec broker kafka-topics --create --topic zookeeper-vacation-ideas --boostrap-server localhost:9092

$ docker-compose exec broker kafka-producer-perf-test --topic zookeeper-vacation-ideas \
    --num-records 200 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=localhost:9092 \
        compression.type=none \
        batch.size=8196
```


Note: the `update_run.sh` is to get around some checks in the cp-kafka docker image. There are plans to change those checks in the future.
The scipt also formats the storage volumes with a random uuid for the cluster. Formatting kafka storage is very important in production environments.