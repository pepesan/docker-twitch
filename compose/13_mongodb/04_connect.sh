#!/bin/bash

mongosh "mongodb://localhost:27017" --eval "db.adminCommand('ping')"

