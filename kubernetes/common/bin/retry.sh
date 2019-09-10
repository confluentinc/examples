function retry() {
  local retries=$1
  shift
  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1 ))
    if [[ ${count} -lt ${retries} ]]; then
      echo "Retry $count/$retries exited ${exit}, retrying in ${wait}  seconds..."
      sleep ${wait}
    else
      echo "Retry $count/$retries exited ${exit}, no more retries left."
      exit 1
      return 1
    fi
  done

  return 0
}

