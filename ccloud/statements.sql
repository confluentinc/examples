CREATE STREAM pageviews_original WITH (kafka_topic='pageviews', value_format='AVRO');
CREATE TABLE users_original (id STRING PRIMARY KEY) WITH (kafka_topic='users', value_format='AVRO');
CREATE STREAM pageviews_female AS SELECT users_original.id AS userid, pageid, regionid, gender FROM pageviews_original LEFT JOIN users_original ON pageviews_original.userid = users_original.id WHERE gender = 'FEMALE';
CREATE STREAM pageviews_female_like_89 AS SELECT * FROM pageviews_female WHERE regionid LIKE '%_8' OR regionid LIKE '%_9';
CREATE TABLE pageviews_regions AS SELECT gender, regionid , COUNT(*) AS numusers FROM pageviews_female WINDOW TUMBLING (size 30 second) GROUP BY gender, regionid HAVING COUNT(*) > 1;
