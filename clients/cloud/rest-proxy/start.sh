#!/bin/bash

./admin.sh
./produce.sh

echo -e "\nSleeping 10 seconds between produce and consume"
sleep 10

./consume.sh

