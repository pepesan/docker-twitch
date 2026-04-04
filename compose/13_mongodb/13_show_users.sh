#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/admin?authSource=admin" --quiet --eval '
printjson(db.getUsers());
'