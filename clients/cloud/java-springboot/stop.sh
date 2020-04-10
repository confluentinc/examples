#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

echo -e "${RED} 🍃 \tStopping Spring Boot application (Vanila Kafka API)... ${NC}"
kill `cat PID.app` 

echo -e "${RED} 🍃 \tStopping Spring Boot application (Kafka Streams)... ${NC}"
kill `cat PID.streams` 

rm PID.app
rm PID.streams