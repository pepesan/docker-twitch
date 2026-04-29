#!/bin/bash

CONSUMER_GROUP_NAME=console-consumer-67579
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group ${CONSUMER_GROUP_NAME}
# Muestra para cada partición del topic:
#
#qué offset tiene el broker (último mensaje escrito)
#qué offset tiene el consumidor (último mensaje leído)
#el lag — la diferencia entre ambos, es decir, cuántos mensajes tiene pendientes de procesar