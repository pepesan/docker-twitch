#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/analytics?authSource=admin" --quiet --eval '
printjson(db.getUsers());
'