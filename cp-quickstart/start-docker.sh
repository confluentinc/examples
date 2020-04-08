#!/bin/bash

# Source library
. ../utils/helper.sh

[[ -d "cp-all-in-one" ]] || git clone https://github.com/confluentinc/cp-all-in-one.git
(cd cp-all-in-one && git fetch && git checkout ${CONFLUENT_RELEASE_TAG_OR_BRANCH} && git pull)

cp docker-compose-overrides.yml cp-all-in-one/cp-all-in-one/.
docker-compose -f cp-all-in-one/cp-all-in-one/docker-compose.yml up -d

sleep 60

. ./connectors/submit_datagen_pageviews_config.sh
. ./connectors/submit_datagen_users_config.sh

# Run the KSQL queries
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/statements.sql';
exit ;
EOF"
