#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo -e "multi-datacenter example: validate that the script at ${DIR}/../read-topics.sh completes"

${DIR}/../read-topics.sh
