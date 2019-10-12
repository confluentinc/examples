# Running RBAC on docker-compose

This docker-compose based setup includes:

- Zookeeper
- OpenLDAP
- Kafka with MDS, connected to the OpenLDAP
- Schema Registry
- KSQL
- Connect
- Rest Proxy
- C3

## Prerequisites

---

- docker
- `zookeeper-shell` must be on your `PATH`
- [Confluent CLI](https://docs.confluent.io/current/cli/index.html)

## Image Versions

---

- You can use production or pre-production images. This is configured via environment variables `PREFIX` and `TAG`.
  - `PREFIX` is appended before the actual image name, before `/`
  - `TAG` is a docker tag, appended after the `:`
  - E.g. with `PREFIX=confluentinc` and `TAG=5.3.1`, kafka will use the following image: `confluentinc/cp-server:5.3.1`
  - If these variables are not set in the shell, they will be read from the `.env` file. Shell variables override whatever is set in the `.env` file
  - You can also edit `.env` file directly
  - This means all images would use the same tag and prefix. If you need to customize this behavior, edit the `docker-compose.yml` file

## Getting Started

---

To start confluent platform, run

```
./confluent-start.sh
```

You can optionally pass in where `-p project-name` to name the docker-compose project, otherwise it defaults to `rbac`. You can use standard docker-compose commands like this listing all containers:

```
docker-compose -p rbac ps
```

or tail Control Center logs:

```
docker-compose -p rbac logs --t 200 -f control-center
```

The script will print you cluster ids to use in assigning role bindings

Kafka broker is available at `localhost:9094` (note, not 9092). All other services are at localhost with standard ports (e.g. C3 is 9021 etc)

| Service         | Host:Port        |
| --------------- | ---------------- |
| Kafka           | `localhost:9094` |
| MDS             | `localhost:8090` |
| C3              | `localhost:9021` |
| Connect         | `localhost:8083` |
| KSQL            | `localhost:8088` |
| OpenLDAP        | `localhost:389`  |
| Schema Registry | `localhost:8081` |

### Granting Rolebindings

---

Login to CLI as `professor:professor` as a super user to grant initial role bindings

```
confluent login --url http://localhost:8090
```

Set `KAFKA_CLUSTER_ID`

```
KAFKA_CLUSTER_ID=$(zookeeper-shell $ZK_HOST get /cluster/id 2> /dev/null | grep version | jq -r .id)
```

Grant `User:bender` ResourceOwner to prefix `Topic:foo` on Kafka cluster `KAFKA_CLUSTER_ID`

```
confluent iam rolebinding create --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID --resource Topic:foo --prefix
```

List the roles of `User:bender` on Kafka cluster `KAFKA_CLUSTER_ID`
```
confluent iam rolebinding list --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID 
```

General Listing syntax
``` 
confluent iam rolebinding list User:[username] [clusters and resources you want to view their roles on]
```

General rolebinding syntax
```
confluent iam rolebinding create --role [role name] --principal User:[username] --resource [resource type]:[resource name] --[cluster type]-cluster-id [insert cluster id] 
```
available role types and permissions can be found [Here](https://docs.confluent.io/current/security/rbac/rbac-predefined-roles.html)

resource types include: Cluster, Group, Subject, Connector, TransactionalId, Topic
### Users

---

| Description     | Name           | Role        |
| --------------- | -------------- | ----------- |
| Super User      | User:professor | SystemAdmin |
| Connect         | User:fry       | SystemAdmin |
| Schema Registry | User:leela     | SystemAdmin |
| KSQL            | User:zoidberg  | SystemAdmin |
| C3              | User:hermes    | SystemAdmin |
| Test User       | User:bender    | \<none>     |

- User `bender:bender` doesn't have any role bindings set up and can be used as a user under test
  - You can use `./client-configs/bender.properties` file to authenticate as `bender` from kafka console commands (like `kafka-console-producer`, `kafka-console-consumer`, `kafka-topics` and the like)
  - This file is also mounted into the broker docker container, so you can `docker-compose -p [project-name] exec broker /bin/bash` to open bash on broker and then use console commands with `/etc/client-configs/bender.properties`
  - When running console commands from inside the broker container, use `localhost:9092`
- All users have password which is the same as their user name, except `amy`. Her password I don't know, but it isn't `amy` :). So I usually connect to OpenLDAP via Apache Directory Studio and change her password to `amy`. Then use her as a second user under test.
