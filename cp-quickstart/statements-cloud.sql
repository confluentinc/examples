CREATE STREAM pageviews WITH (kafka_topic='pageviews', value_format='AVRO');
CREATE TABLE users (id STRING PRIMARY KEY) WITH (kafka_topic='users', value_format='PROTOBUF');
CREATE STREAM pageviews_female AS SELECT users.id AS userid, pageid, regionid, gender FROM pageviews LEFT JOIN users ON pageviews.userid = users.id WHERE gender = 'FEMALE';
CREATE STREAM pageviews_female_like_89 AS SELECT * FROM pageviews_female WHERE regionid LIKE '%_8' OR regionid LIKE '%_9';
CREATE TABLE pageviews_regions WITH (key_format='JSON') AS SELECT gender, regionid , COUNT(*) AS numusers FROM pageviews_female WINDOW TUMBLING (size 30 second) GROUP BY gender, regionid HAVING COUNT(*) > 1;
CREATE STREAM accomplished_female_readers WITH (value_format='JSON_SR') AS SELECT * FROM PAGEVIEWS_FEMALE WHERE CAST(SPLIT(PAGEID,'_')[2] as INT) >= 50;
