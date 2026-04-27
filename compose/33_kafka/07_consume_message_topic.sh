#!/bin/bash

docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic eventos-demo \
  --from-beginning
