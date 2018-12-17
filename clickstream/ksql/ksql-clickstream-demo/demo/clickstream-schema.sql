set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='10000000';
set 'auto.offset.reset'='earliest';

-- 1. SOURCE of ClickStream
CREATE STREAM clickstream (_time bigint,time varchar, ip varchar, request varchar, status int, userid int, bytes bigint, agent varchar) with (kafka_topic = 'clickstream', value_format = 'json');


----------------------------------------------------------------------------------------------------------------------------
-- A series of basic clickstream-analytics
--
-- Min, Max, UDFs etc
----------------------------------------------------------------------------------------------------------------------------

 -- number of events per minute - think about key-for-distribution-purpose - shuffling etc - shouldnt use 'userid'
CREATE table events_per_min AS SELECT userid, WindowStart() AS EVENT_TS, count(*) AS events FROM clickstream window TUMBLING (size 60 second) GROUP BY userid;

-- 3. BUILD STATUS_CODES
-- static table
CREATE TABLE clickstream_codes (code int, definition varchar) with (key='code', kafka_topic = 'clickstream_codes', value_format = 'json');

-- 4. BUILD PAGE_VIEWS
CREATE TABLE pages_per_min AS SELECT userid, WindowStart() AS EVENT_TS, count(*) AS pages FROM clickstream WINDOW HOPPING (size 60 second, advance by 5 second) WHERE request like '%html%' GROUP BY userid ;

----------------------------------------------------------------------------------------------------------------------------
-- URL STATUS CODES (Join AND Alert)
--
--
----------------------------------------------------------------------------------------------------------------------------

-- Use 'HAVING' Filter to show ERROR codes > 400 where count > 5
CREATE TABLE ERRORS_PER_MIN_ALERT AS SELECT status, WindowStart() AS EVENT_TS, count(*) AS errors FROM clickstream window HOPPING ( size 30 second, advance by 20 second) WHERE status > 400 GROUP BY status HAVING count(*) > 5 AND count(*) is not NULL;

CREATE table ERRORS_PER_MIN AS SELECT status, WindowStart() AS EVENT_TS, count(*) AS errors FROM clickstream window HOPPING ( size 60 second, advance by 5  second) WHERE status > 400 GROUP BY status;

--Join using a STREAM
CREATE STREAM ENRICHED_ERROR_CODES AS SELECT code, definition FROM clickstream LEFT JOIN clickstream_codes ON clickstream.status = clickstream_codes.code;
-- Aggregate (count&groupBy) using a TABLE-Window
CREATE TABLE ENRICHED_ERROR_CODES_COUNT AS SELECT code, WindowStart() AS EVENT_TS, definition, COUNT(*) AS count FROM ENRICHED_ERROR_CODES WINDOW TUMBLING (size 30 second) GROUP BY code, definition HAVING COUNT(*) > 1;

----------------------------------------------------------------------------------------------------------------------------
-- Clickstream users for enrichment and exception monitoring
--
--
----------------------------------------------------------------------------------------------------------------------------

-- users lookup table
CREATE TABLE WEB_USERS (user_id int, registered_At BIGINT, username varchar, first_name varchar, last_name varchar, city varchar, level varchar) with (key='user_id', kafka_topic = 'clickstream_users', value_format = 'json');

----------------------------------------------------------------------------------------------------------------------------
-- User experience monitoring
--
-- View IP, username and City Versus web-site-activity (hits)
----------------------------------------------------------------------------------------------------------------------------
CREATE STREAM USER_CLICKSTREAM AS SELECT userid, u.username, ip, u.city, request, status, bytes FROM clickstream c LEFT JOIN web_users u ON c.userid = u.user_id;

-- Aggregate (count&groupBy) using a TABLE-Window
CREATE TABLE USER_IP_ACTIVITY AS SELECT username, WindowStart() AS EVENT_TS, ip, city, COUNT(*) AS count FROM USER_CLICKSTREAM WINDOW TUMBLING (size 60 second) GROUP BY username, ip, city HAVING COUNT(*) > 1;

----------------------------------------------------------------------------------------------------------------------------
-- User session monitoring
--
-- Sessionisation using IP addresses - 300 seconds of inactivity expires the session
--
----------------------------------------------------------------------------------------------------------------------------

CREATE TABLE CLICK_USER_SESSIONS AS SELECT username, WindowStart() AS EVENT_TS, count(*) AS events FROM USER_CLICKSTREAM window SESSION (300 second) GROUP BY username;