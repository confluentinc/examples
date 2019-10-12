CREATE STREAM ibmmq
  WITH (KAFKA_TOPIC='ibmmq',
        VALUE_FORMAT='AVRO');

select  * from  CLICKSTREAM
join  IBMMQ WITHIN 5 seconds
on text = username;