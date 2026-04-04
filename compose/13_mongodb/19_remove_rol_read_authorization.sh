#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/analytics?authSource=admin" --eval '
db.revokeRolesFromUser("analize",[ { role:"read", db:"analytics"}]);
db.getUsers();
'