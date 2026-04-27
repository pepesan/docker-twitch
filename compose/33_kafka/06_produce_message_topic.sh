#!/bin/bash

docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic eventos-demo
# Escribe mensajes y pulsa Enter. Ctrl+C para salir.
