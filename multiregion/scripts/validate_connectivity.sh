#!/bin/bash

echo -e "\n\n==> Validate containers can ping each other\n"

for host in broker-west-1 broker-west-2 controller-west controller-central controller-east broker-east-3 broker-east-4; do
  OUTPUT=$(docker compose exec -T broker-west-1 ping $host -c 1)
  if [[ "$OUTPUT" =~ "1 received" ]]; then
    echo "broker-west-1 can ping $host"
  else
    echo "ERROR: broker-west-1 cannot ping $host"
    exit 1
  fi
done
