#!/bin/bash

docker container rm tomcat

docker ps -a | grep tomcat