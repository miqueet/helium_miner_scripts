#!/bin/bash

# Run this script every minute via cron.

LOG_FILE="$HOME/my_logs/consensus.log"
VAL_NAME="lorem-ipsum-dolor"

if [ $(docker exec validator miner info in_consensus) == "true" ]; then
    OUTPUT+=$(date +"%Y-%m-%d %T  ")
    OUTPUT+=$(docker exec validator miner hbbft perf | grep "$VAL_NAME")
    echo "$OUTPUT" >> $LOG_FILE
fi
