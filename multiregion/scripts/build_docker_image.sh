#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../.env

# Confluent's ubi-based Docker images do not have 'tc' installed
echo
echo "Build custom cp-server image with 'tc' installed"
IMAGENAME=localbuild/cp-server-tc:${CONFLUENT_DOCKER_TAG}
docker build --no-cache --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg REPOSITORY=${REPOSITORY} --build-arg IMAGE=cp-server -t $IMAGENAME -f ${DIR}/../Dockerfile ${DIR}/../.
docker image inspect $IMAGENAME >/dev/null 2>&1 || \
   { echo "Docker image $IMAGENAME not found. Please troubleshoot and rerun"; exit 1; }
