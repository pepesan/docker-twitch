#!/bin/bash

echo "Checking Prometheus health and metrics..."
curl -s http://localhost:9090/-/healthy
echo

echo "Checking Prometheus 'up' metric..."
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=up'
echo

echo "Checking 'up' metric for node-exporter..."
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=up{job="node-exporter"}'
echo

echo "Checking CPU usage rate from node-exporter..."
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=rate(node_cpu_seconds_total[1m])'
echo

echo "== Exporter UP =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=up{job="mongodb-exporter"}'
echo
echo

echo "== MongoDB UP =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_up'
echo
echo

echo "== Conexiones actuales =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_ss_connections{conn_type="current"}'
echo
echo

echo "== Conexiones disponibles =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_ss_connections{conn_type="available"}'
echo
echo

echo "== Memoria residente MB =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_memory{type="resident"}'
echo
echo

echo "== Memoria virtual MB =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_memory{type="virtual"}'
echo
echo

echo "== Operaciones acumuladas =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_op_counters_total'
echo
echo

echo "== Rate de operaciones últimos 5m =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=rate(mongodb_op_counters_total[5m])'
echo
echo

echo "== Solo queries por segundo =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=rate(mongodb_op_counters_total{type="query"}[5m])'
echo
echo

echo "== Solo commands por segundo =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=rate(mongodb_op_counters_total{type="command"}[5m])'
echo
echo

echo "== Uptime MongoDB =="
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=mongodb_instance_uptime_seconds'
echo
echo