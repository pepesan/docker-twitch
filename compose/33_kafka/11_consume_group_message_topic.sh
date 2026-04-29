#!/bin/bash
CONSUMER_GROUP_NAME=console-consumer-67579
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic eventos-demo \
  --group ${CONSUMER_GROUP_NAME} \
  --from-beginning
# Ahora escribe desde el productor y verás que el consumidor del grupo recibe los mensajes. Luego, puedes ejecutar el siguiente comando para ver el estado del grupo de consumidores
# ./10_describe_consumer_group.sh