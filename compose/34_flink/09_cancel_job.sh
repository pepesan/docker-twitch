#!/bin/bash

JOB_ID=e89fa783987ab33f044df1e488b8a19b
# Obtener el job ID desde la UI o con flink list
docker exec jobmanager /opt/flink/bin/flink cancel $JOB_ID

