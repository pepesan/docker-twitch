#!/bin/bash

docker compose logs airflow-api-server | grep -i password

