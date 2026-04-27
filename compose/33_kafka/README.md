# Demo Apache Kafka — Docker Compose

## Servicios

| Servicio  | URL                    | Descripción                        |
|-----------|------------------------|------------------------------------|
| Kafka     | localhost:9092         | Broker KRaft (sin ZooKeeper)       |
| Kafka UI  | http://localhost:8080  | Interfaz web — topics, mensajes    |

## Arrancar

```bash
docker compose up -d
docker compose ps   # esperar kafka healthy
```

## Demo desde línea de comandos

### Crear un topic

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic eventos-demo \
  --partitions 3 \
  --replication-factor 1
```

### Listar topics

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list
```

### Producir mensajes (producer)

```bash
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic eventos-demo
# Escribe mensajes y pulsa Enter. Ctrl+C para salir.
```

### Consumir mensajes (consumer)

```bash
# En otra terminal — lee desde el principio
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic eventos-demo \
  --from-beginning
```

### Ver detalles de un topic (particiones, offsets)

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe --topic eventos-demo
```

### Consumer groups

```bash
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --list

docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group <nombre-grupo>
```

## Parar

```bash
docker compose down        # mantiene datos
docker compose down -v     # borra también el volumen
```