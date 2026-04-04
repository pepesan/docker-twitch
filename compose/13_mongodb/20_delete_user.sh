#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/analytics?authSource=admin" ./scripts/05_delete_read_user.js
