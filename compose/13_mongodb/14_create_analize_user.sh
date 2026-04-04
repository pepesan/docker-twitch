#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/admin?authSource=admin" ./scripts/03_create_read_user.js

