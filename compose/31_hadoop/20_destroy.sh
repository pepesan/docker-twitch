#!/bin/bash

docker compose down -v

docker volume rm 31_hadoop_namenode_data 31_hadoop_datanode_data
