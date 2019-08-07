#!/bin/bash
retry() {
    local -r -i max_attempts="$1"; shift
    local -r -i sleep_interval="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1
 
    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Failed after $attempt_num attempts"
            return 1
        else
            printf "."
            ((attempt_num++))
            sleep $sleep_interval
        fi
    done
    printf "\n"
}

container_healthy() {
    local name=$1
    local container=$(docker-compose -p rbac ps -q $1)
    local healthy=$(docker inspect --format '{{ .State.Health.Status }}' $container)
    if [ $healthy == healthy ]
    then
        printf "$1 is healthy"
        return 0
    else
        return 1
    fi
}