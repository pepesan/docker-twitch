#!/bin/bash

docker container rm tomcat-sample-war

docker ps -a | grep tomcat-sample-war