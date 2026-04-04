#!/bin/bash

mongosh "mongodb://analize:root@localhost:27017/analytics?authSource=analytics" --eval '
printjson(db.getCollectionNames());
db.users.find().pretty();
'