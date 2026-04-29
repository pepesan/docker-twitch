#!/bin/bash

docker exec -it jobmanager bash

# Lanza proceso
# /opt/flink/bin/flink run  /opt/flink/examples/streaming/TopSpeedWindowing.jar
# Ve a http://localhost:8081 para ver el job corriendo en tiempo real:

#- (menu principal) Jobs -> Running Jobs → entra al job activo
# Hay deberíamos ver el job corriendo en overview debería parecer el trabajo en marcha

#- (menu principal)  Task Managers → listado -> entra en el Task Manager activo

