#!/bin/bash

if [ "$#" -eq 2 ]; then
    stime=$(date +%s -d "$1")
    etime=$(date +%s -d "$2")
else
    echo "Usage: $0 <stime> <etime>"
    exit 1
fi

time_span=$((${etime} - ${stime}))
echo "time_span = "${time_span}
