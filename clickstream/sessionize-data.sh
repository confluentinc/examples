#!/bin/bash

# The purpose of this script is to create sessions of user clicks
# The demo uses a table CLICK_USER_SESSIONS to show a count of user activity
# for a given user session.  All clicks from the user count towards the current
# session.  If a user is inactive for 30 seconds, any subsequent activity is counted
# towards a new session.

# To simulate these user sessions, the script pauses the DATAGEN_CLICKSTREAM connector 
# every 90 seconds for a 35 second period of inactivity.  By stopping the DATAGEN_CLICKSTREAM connector 
# for more than 30 seconds, you are guaranteed to see user sessions.

# Session windows are because they are driven by user behavior and
# other window implementations are driven only by time.


echo "Running for 90 seconds to allow clickstream data to generate"

sleep 90
for i in {1..100}; do

 
 docker-compose exec ksqldb-server curl -X PUT localhost:8083/connectors/DATAGEN_CLICKSTREAM/pause

 echo "Pausing the clickstream datagen for 35 seconds"
 sleep 35


 docker-compose exec ksqldb-server curl -X PUT localhost:8083/connectors/DATAGEN_CLICKSTREAM/resume

 echo "Resuming the clickstream datagen for 90 seconds. Then the cycle will repeat"
 sleep 90

done


echo "Ending session data"
