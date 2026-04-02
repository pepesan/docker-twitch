#!/bin/bash

open http://localhost:3001

# login admin/admin
# pide nueva password
# mete el datasource de prometheus desde Connections -> Datasources -> Add Data source
# Elige Prometheus, y en URL pones la url del prometheus, que es http://prometheus:9090,
# y le das a Save & Test, y debería decir que se ha conectado correctamente.
# Importa un dashboard  1860, debería mostrarte las métricas del node exporter.
# Importa otro dashboard 20867, y elige el datasource de prometheus, y debería mostrarte las métricas del mongodb exporter.





