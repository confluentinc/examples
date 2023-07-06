control-center-stop
ksql-server-stop
kafka-rest-stop

# Shut down connect worker as documented here: https://docs.confluent.io/platform/current/connect/userguide.html#shut-down-kconnect-long
# The square bracket around 'C' will match the process we want but not the grep command itself. Note that this will
# kill multiple distributed workers if there are any
CONNECT_WORKER_PID=`ps aux | grep '[C]onnectDistributed' | awk '{print $2}'`
if [[ $CONNECT_WORKER_PID ]]; then
  echo "Stopping distributed worker with process ID(s) $CONNECT_WORKER_PID"
  kill $CONNECT_WORKER_PID
fi
schema-registry-stop
kafka-server-stop
zookeeper-server-stop