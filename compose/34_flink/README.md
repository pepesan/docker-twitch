# Demo Apache Flink — Docker Compose

## Servicios

| Servicio     | URL                    | Descripción                              |
|--------------|------------------------|------------------------------------------|
| JobManager   | http://localhost:8081  | Flink UI — jobs, tasks, checkpoints      |
| TaskManager  | —                      | Worker con 2 task slots                  |

## Arrancar

```bash
docker compose up -d
docker compose ps
```

## Demo — job de ejemplo incluido en Flink

Flink incluye ejemplos preinstalados. El más ilustrativo es **WordCount** en modo streaming:

```bash
# Entrar al contenedor del JobManager
docker exec -it jobmanager bash

# Ejecutar WordCount sobre datos generados aleatoriamente
/opt/flink/bin/flink run \
  /opt/flink/examples/streaming/WordCount.jar

# Ver resultado en los logs del TaskManager
exit
docker logs taskmanager | grep -A5 "WordCount"
```

## Demo — TopSpeedWindowing (ventanas)

Demuestra ventanas de tiempo con eventos de velocidad de vehículos:

```bash
docker exec -it jobmanager bash

/opt/flink/bin/flink run \
  /opt/flink/examples/streaming/TopSpeedWindowing.jar
```

Ve a http://localhost:8081 para ver el job corriendo en tiempo real:
- Running Jobs → el job activo
- Task Managers → slots usados
- Job Graph → el DAG de operadores

## Listar jobs activos

```bash
docker exec jobmanager /opt/flink/bin/flink list
```

## Cancelar un job

```bash
# Obtener el job ID desde la UI o con flink list
docker exec jobmanager /opt/flink/bin/flink cancel <JOB_ID>
```

## Parar el clúster

```bash
docker compose down -v
```