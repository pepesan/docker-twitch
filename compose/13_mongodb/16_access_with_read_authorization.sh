#!/bin/bash

RESULT=$(mongosh "mongodb://analize:root@localhost:27017/analytics?authSource=analytics" --quiet --eval 'db.runCommand({ connectionStatus: 1 }).ok' 2>/dev/null | tr -d '[:space:]')

if [ "$RESULT" = "1" ]; then
  echo "OK"
else
  echo "ERROR"
  exit 1
fi

