#!/bin/bash

mkdir -p logs

sudo chmod -R 777 dags/ data/ logs/

# Sólo en Linux
echo -e "AIRFLOW_UID=$(id -u)" > .env

