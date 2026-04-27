#!/bin/bash

docker logs jobmanager | grep -A20 "WordCount"
