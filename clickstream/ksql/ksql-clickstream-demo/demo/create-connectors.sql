CREATE SOURCE CONNECTOR datagen_clickstream_codes WITH (
  'connector.class'          = 'io.confluent.kafka.connect.datagen.DatagenConnector',
  'kafka.topic'              = 'clickstream_codes',
  'quickstart'               = 'clickstream_codes',
  'maxInterval'              = '20',
  'format'                   = 'json',
  'key.converter'            = 'org.apache.kafka.connect.converters.IntegerConverter');

CREATE SOURCE CONNECTOR datagen_clickstream_users WITH (
  'connector.class'          = 'io.confluent.kafka.connect.datagen.DatagenConnector',
  'kafka.topic'              = 'clickstream_users',
  'quickstart'               = 'clickstream_users',
  'maxInterval'              = '10',
  'format'                   = 'json',
  'key.converter'            = 'org.apache.kafka.connect.converters.IntegerConverter');

CREATE SOURCE CONNECTOR datagen_clickstream WITH (
  'connector.class'          = 'io.confluent.kafka.connect.datagen.DatagenConnector',
  'kafka.topic'              = 'clickstream',
  'quickstart'               = 'clickstream',
  'maxInterval'              = '30',
  'format'                   = 'json');
