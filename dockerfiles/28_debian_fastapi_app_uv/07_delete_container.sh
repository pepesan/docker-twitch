#!/bin/bash

docker container rm app-python-uv

docker ps -a | grep app-python-uv