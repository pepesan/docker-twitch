#!/bin/bash

JOB_ID=a498148331be087bf1e747d1ee0ed618
# Obtener el job ID desde la UI o con flink list
docker exec jobmanager /opt/flink/bin/flink cancel $JOB_ID

