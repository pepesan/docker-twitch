# Ejemplo de uso de redes en contenedores

## Creación de la red
```shell
docker network create red_ping
```
## Levantando los contenedores
```shell
docker compose up -d
```
## Nos metemos en un contenedor
```shell
docker compose exec ping1 /bin/bash
```
## Hacemos ping al otro servicio
```shell
ping ping2
ping ping22
```