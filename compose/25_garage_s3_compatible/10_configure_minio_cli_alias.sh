#!/bin/bash
# pilla estos datos del ./06_create_key.sh
KEY_ID=GK3eb12766ef42bffaa1e1f635
SECRET_KEY=e74b6fa840cbd4818ba7d2ff3c3abc6b250fe4f4cb612213872962878adb989b
mc alias set garage http://localhost:3900 $KEY_ID $SECRET_KEY --api S3v4





