#!/bin/bash

docker compose exec airflow-scheduler python -c "import pandas"
