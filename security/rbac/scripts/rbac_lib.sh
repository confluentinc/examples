#!/bin/bash

function create_temp_configs() {

  BANNER=$(cat <<-END


------------------------------------------------------
The following lines are added by the RBAC demo
------------------------------------------------------


END
)

  FILE_ORIGINAL=$1
  FILE_BACKUP=$2
  FILE_DELTA=$3

  echo -e "\n\n\n*** $FILE_ORIGINAL ***\n\n\n"

  cp $FILE_ORIGINAL $FILE_BACKUP
  echo "$BANNER" >> $FILE_ORIGINAL
  cat $FILE_DELTA >> $FILE_ORIGINAL

  return 0

}


function restore_configs() {

  FILE_ORIGINAL=$1
  FILE_BACKUP=$2
  FILE_SAVE=$3

  cp $FILE_ORIGINAL $FILE_SAVE
  cp $FILE_BACKUP $FILE_ORIGINAL

  return 0
}


function login_mds() {

  MDS_URL=$1

  echo -e "\n# Login"
  OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $MDS_URL
  expect "Username: "
  send "${USER_ADMIN_MDS}\r";
  expect "Password: "
  send "${USER_ADMIN_MDS}1\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)

  echo "$OUTPUT"
  if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
    echo "Failed to log into your Metadata Server.  Please check all parameters and run again"
    exit 1
  fi

  return 0
}
