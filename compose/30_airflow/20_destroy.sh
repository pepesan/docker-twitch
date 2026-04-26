#!/bin/bash

docker compose down

sudo rm -rf logs/* data/output/*

docker volume rm 30_airflow_postgres_data
