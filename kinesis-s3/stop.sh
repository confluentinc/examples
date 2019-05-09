#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

confluent destroy
