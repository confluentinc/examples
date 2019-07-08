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
