

-- 1. SOURCE of ClickStream
--DROP STREAM IF EXISTS clickstream;
CREATE STREAM clickstream (_time bigint,time varchar, ip varchar, request varchar, status int, userid int, bytes bigint, agent varchar) with (kafka_topic = 'clickstream', value_format = 'json');


----------------------------------------------------------------------------------------------------------------------------
-- A series of basic clickstream-analytics
--
-- Min, Max, UDFs etc
----------------------------------------------------------------------------------------------------------------------------

 -- number of events per minute - think about key-for-distribution-purpose - shuffling etc - shouldnt use 'userid'
--DROP TABLE IF EXISTS events_per_min;
CREATE table events_per_min AS SELECT userid, count(*) AS events FROM clickstream window TUMBLING (size 60 second) GROUP BY userid;

-- 3. BUILD STATUS_CODES
-- static table
--DROP TABLE IF EXISTS clickstream_codes;
CREATE TABLE clickstream_codes (code int, definition varchar) with (key='code', kafka_topic = 'clickstream_codes', value_format = 'json');

-- 4. BUILD PAGE_VIEWS
--DROP TABLE IF EXISTS pages_per_min;
CREATE TABLE pages_per_min AS SELECT userid, count(*) AS pages FROM clickstream WINDOW HOPPING (size 60 second, advance by 5 second) WHERE request like '%html%' GROUP BY userid ;

----------------------------------------------------------------------------------------------------------------------------
-- URL STATUS CODES (Join AND Alert)
--
--
----------------------------------------------------------------------------------------------------------------------------

-- Use 'HAVING' Filter to show ERROR codes > 400 where count > 5
--DROP TABLE IF EXISTS ERRORS_PER_MIN_ALERT;
CREATE TABLE ERRORS_PER_MIN_ALERT AS SELECT status, count(*) AS errors FROM clickstream window HOPPING ( size 30 second, advance by 20 second) WHERE status > 400 GROUP BY status HAVING count(*) > 5 AND count(*) is not NULL;

--DROP TABLE IF EXISTS ERRORS_PER_MIN;
CREATE table ERRORS_PER_MIN AS SELECT status, count(*) AS errors FROM clickstream window HOPPING ( size 60 second, advance by 5  second) WHERE status > 400 GROUP BY status;

-- VIEW - Enrich Codes with errors with Join to Status-Code definition
--DROP STREAM IF EXISTS ENRICHED_ERROR_CODES;
--DROP TABLE IF EXISTS ENRICHED_ERROR_CODES_COUNT;

--Join using a STREAM
CREATE STREAM ENRICHED_ERROR_CODES AS SELECT code, definition FROM clickstream LEFT JOIN clickstream_codes ON clickstream.status = clickstream_codes.code;
-- Aggregate (count&groupBy) using a TABLE-Window
CREATE TABLE ENRICHED_ERROR_CODES_COUNT AS SELECT code, definition, COUNT(*) AS count FROM ENRICHED_ERROR_CODES WINDOW TUMBLING (size 30 second) GROUP BY code, definition HAVING COUNT(*) > 1;


----------------------------------------------------------------------------------------------------------------------------
-- Clickstream users for enrichment and exception monitoring
--
--
----------------------------------------------------------------------------------------------------------------------------

-- users lookup table
--DROP TABLE IF EXISTS WEB_USERS;
CREATE TABLE WEB_USERS (user_id int, registered_At BIGINT, username varchar, first_name varchar, last_name varchar, city varchar, level varchar) with (key='user_id', kafka_topic = 'clickstream_users', value_format = 'json');

-- Clickstream enriched with user account data
--DROP STREAM IF EXISTS customer_clickstream;
CREATE STREAM customer_clickstream WITH (PARTITIONS=2) AS SELECT userid, u.first_name, u.last_name, u.level, time, ip, request, status, agent FROM clickstream c LEFT JOIN web_users u ON c.userid = u.user_id;

-- Find error views by important users
----DROP STREAM IF EXISTS platinum_customers_with_errors
--CREATE stream platinum_customers_with_errors WITH (PARTITIONS=2) AS seLECT * FROM customer_clickstream WHERE status > 400 AND level = 'Platinum';

-- Find error views by important users in one shot
----DROP STREAM IF EXISTS platinum_errors;
--CREATE STREAM platinum_errors WITH (PARTITIONS=2) AS SELECT userid, u.first_name, u.last_name, u.city, u.level, time, ip, request, status, agent FROM clickstream c LEFT JOIN web_users u ON c.userid = u.user_id WHERE status > 400 AND level = 'Platinum';
--
---- Trend of errors from important users
----DROP TABLE IF EXISTS platinum_page_errors_per_5_min;
--CREATE TABLE platinum_errors_per_5_min AS SELECT userid, first_name, last_name, city, count(*) AS running_count FROM platinum_errors WINDOW TUMBLING (SIZE 5 MINUTE) WHERE request LIKE '%html%' GROUP BY userid, first_name, last_name, city;


----------------------------------------------------------------------------------------------------------------------------
-- User experience monitoring
--
-- View IP, username and City Versus web-site-activity (hits)
----------------------------------------------------------------------------------------------------------------------------
--DROP STREAM IF EXISTS USER_CLICKSTREAM;
CREATE STREAM USER_CLICKSTREAM AS SELECT userid, u.username, ip, u.city, request, status, bytes FROM clickstream c LEFT JOIN web_users u ON c.userid = u.user_id;

-- Aggregate (count&groupBy) using a TABLE-Window
--DROP TABLE IF EXISTS USER_IP_ACTIVITY;
CREATE TABLE USER_IP_ACTIVITY AS SELECT username, ip, city, COUNT(*) AS count FROM USER_CLICKSTREAM WINDOW TUMBLING (size 60 second) GROUP BY username, ip, city HAVING COUNT(*) > 1;

----------------------------------------------------------------------------------------------------------------------------
-- User session monitoring
--
-- Sessionisation using IP addresses - 300 seconds of inactivity expires the session
--
----------------------------------------------------------------------------------------------------------------------------

--DROP TABLE IF EXISTS CLICK_USER_SESSIONS;
CREATE TABLE CLICK_USER_SESSIONS AS SELECT username, count(*) AS events FROM USER_CLICKSTREAM window SESSION (300 second) GROUP BY username;

----------------------------------------------------------------------------------------------------------------------------
-- Blog Article tracking user-session and bandwidth
--
-- Sessionisation using IP addresses - 300 seconds of inactivity expires the session
--
----------------------------------------------------------------------------------------------------------------------------

----DROP TABLE IF EXISTS PER_USER_KBYTES;
--CREATE TABLE PER_USER_KBYTES AS SELECT username, sum(bytes)/1024 AS kbytes FROM USER_CLICKSTREAM window SESSION (300 second) GROUP BY username;

----DROP TABLE IF EXISTS MALICIOUS_USER_SESSIONS;
--CREATE TABLE MALICIOUS_USER_SESSIONS AS SELECT username, ip,  sum(bytes)/1024 AS kbytes FROM USER_CLICKSTREAM window SESSION (300 second) GROUP BY username, ip  HAVING sum(bytes)/1024 > 50;

