#!/bin/bash

docker container rm sample-war

docker ps -a | grep sample-war