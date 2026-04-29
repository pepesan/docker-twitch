# Demo Hadoop — Docker Compose

## Requisitos
- Docker Desktop (o Docker Engine + Compose plugin)
- 4 GB RAM disponibles

## Arrancar el clúster

```bash
docker compose up -d
```

Espera ~30 segundos a que el NameNode inicialice.

## Interfaces web

| Componente      | URL                        | Descripción              |
|-----------------|----------------------------|--------------------------|
| NameNode (HDFS) | http://localhost:9870       | Estado del sistema HDFS  |
| ResourceManager | http://localhost:8088       | Jobs y recursos YARN     |

## Comandos HDFS básicos (para la demo)

```bash
# Entrar al contenedor namenode
docker exec -it namenode bash

# Crear un directorio en HDFS
hdfs dfs -mkdir -p /user/demo

# Subir un fichero local a HDFS
hdfs dfs -put /etc/hosts /user/demo/hosts.txt

# Listar ficheros
hdfs dfs -ls /user/demo

# Leer un fichero
hdfs dfs -cat /user/demo/hosts.txt

# Ver uso del sistema de ficheros
hdfs dfs -df -h
```
Nos salimos con exit

## Ejecutar un job MapReduce de ejemplo (WordCount)

```bash
docker exec -it namenode bash

# Crear datos de entrada
echo "hadoop spark kafka flink hadoop spark hadoop" > /tmp/input.txt
hdfs dfs -mkdir -p /user/demo/input
hdfs dfs -put /tmp/input.txt /user/demo/input/

# Ejecutar WordCount (incluido en hadoop-mapreduce-examples)
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount /user/demo/input /user/demo/output

# Ver resultado
hdfs dfs -cat /user/demo/output/part-r-00000
```
Nos salimos con exit
## Parar el clúster

```bash
docker compose down
```

Para borrar también los volúmenes de datos:

```bash
docker compose down -v
```