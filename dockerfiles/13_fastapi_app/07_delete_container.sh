#!/bin/bash

docker container rm app-python

docker ps -a | grep app-python