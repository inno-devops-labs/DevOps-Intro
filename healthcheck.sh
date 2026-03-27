#!/bin/bash

DESIRED_MD5=$(md5sum desired-state.txt | awk '{print $1}')
CURRENT_MD5=$(md5sum current-state.txt | awk '{print $1}')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$DESIRED_MD5" = "$CURRENT_MD5" ]; then
    echo "OK: state is synchronized"
    echo "$TIMESTAMP OK desired=$DESIRED_MD5 current=$CURRENT_MD5" >> health.log
else
    echo "CRITICAL: drift detected"
    echo "$TIMESTAMP CRITICAL desired=$DESIRED_MD5 current=$CURRENT_MD5" >> health.log
fi
