---------------------------------------------------------------------------------------------------
-- Create sources:
---------------------------------------------------------------------------------------------------
-- stream of user clicks:
CREATE STREAM clickstream (
        _time bigint,
        time varchar,
        ip varchar,
        request varchar,
        status int,
        userid int,
        bytes bigint,
        agent varchar
    ) with (
        kafka_topic = 'clickstream',
        value_format = 'json'
    );

-- error code lookup table:
CREATE TABLE clickstream_codes (
        code int primary key,
        definition varchar
    ) with (
        kafka_topic = 'clickstream_codes',
        value_format = 'json'
    );

-- users lookup table:
CREATE TABLE WEB_USERS (
        user_id int primary key,
        registered_At BIGINT,
        username varchar,
        first_name varchar,
        last_name varchar,
        city varchar,
        level varchar
    ) with (
        kafka_topic = 'clickstream_users',
        value_format = 'json'
    );

---------------------------------------------------------------------------------------------------
-- Build materialized stream views:
---------------------------------------------------------------------------------------------------

-- enrich click-stream with more user information:
CREATE STREAM USER_CLICKSTREAM AS
    SELECT
        userid,
        u.username,
        ip,
        u.city,
        request,
        status,
        bytes
    FROM clickstream c
        LEFT JOIN web_users u ON c.userid = u.user_id;

-- Enrich click-stream with more information about error codes:
CREATE STREAM ENRICHED_ERROR_CODES AS
    SELECT
        code,
        definition
    FROM clickstream
        LEFT JOIN clickstream_codes ON clickstream.status = clickstream_codes.code;

---------------------------------------------------------------------------------------------------
-- Build materialized table views:
---------------------------------------------------------------------------------------------------

-- Per-userId tables -----------------------------------------------------------------------------

-- Table of events per minute for each user:
CREATE table events_per_min AS
    SELECT
        userid as k1,
        AS_VALUE(userid) as userid,
        WINDOWSTART as EVENT_TS,
        count(*) AS events
    FROM clickstream window TUMBLING (size 60 second)
    GROUP BY userid;

-- Table of html pages per minute for each user:
CREATE TABLE pages_per_min AS
    SELECT
        userid as k1,
        AS_VALUE(userid) as userid,
        WINDOWSTART as EVENT_TS,
        count(*) AS pages
    FROM clickstream WINDOW HOPPING (size 60 second, advance by 5 second)
    WHERE request like '%html%'
    GROUP BY userid;

-- Per-username tables ----------------------------------------------------------------------------

-- User sessions table - 30 seconds of inactivity expires the session
-- Table counts number of events within the session
CREATE TABLE CLICK_USER_SESSIONS AS
    SELECT
        username as K,
        AS_VALUE(username) as username,
        WINDOWEND as EVENT_TS,
        count(*) AS events
    FROM USER_CLICKSTREAM window SESSION (30 second)
    GROUP BY username;

-- Per-status tables ------------------------------------------------------------------------------

-- number of errors per min, using 'HAVING' Filter to show ERROR codes > 400 where count > 5
CREATE TABLE ERRORS_PER_MIN_ALERT AS
    SELECT
        status as k1,
        AS_VALUE(status) as status,
        WINDOWSTART as EVENT_TS,
        count(*) AS errors
    FROM clickstream window HOPPING (size 60 second, advance by 20 second)
    WHERE status > 400
    GROUP BY status
    HAVING count(*) > 5 AND count(*) is not NULL;

-- number of errors per min
CREATE TABLE ERRORS_PER_MIN AS
    SELECT
        status as k1,
        AS_VALUE(status) as status,
        WINDOWSTART as EVENT_TS,
        count(*) AS errors
    FROM clickstream window HOPPING (size 60 second, advance by 5  second)
    WHERE status > 400
    GROUP BY status;

-- Per-error code tables --------------------------------------------------------------------------

-- Enriched error codes table:
-- Aggregate (count&groupBy) using a TABLE-Window
CREATE TABLE ENRICHED_ERROR_CODES_COUNT AS
    SELECT
        code as k1,
        definition as K2,
        AS_VALUE(code) as code,
        WINDOWSTART as EVENT_TS,
        AS_VALUE(definition) as definition,
        COUNT(*) AS count
    FROM ENRICHED_ERROR_CODES WINDOW TUMBLING (size 30 second)
    GROUP BY code, definition
    HAVING COUNT(*) > 1;

-- Enriched user details table:
-- Aggregate (count&groupBy) using a TABLE-Window
CREATE TABLE USER_IP_ACTIVITY AS
    SELECT
        username as k1,
        ip as k2,
        city as k3,
        AS_VALUE(username) as username,
        WINDOWSTART as EVENT_TS,
        AS_VALUE(ip) as ip,
        AS_VALUE(city) as city,
        COUNT(*) AS count
    FROM USER_CLICKSTREAM WINDOW TUMBLING (size 60 second)
    GROUP BY username, ip, city
    HAVING COUNT(*) > 1;
