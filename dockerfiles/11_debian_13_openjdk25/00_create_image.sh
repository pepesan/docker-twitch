#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=debian-openjdk
# construir la imagen en base al Dockerfile
## build es el comando principal
## -t define el tag asociado a la imagen
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
## . pilla el Dockerfile que hay en el directorio actual
docker build -t $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:latest .
## define otro tag con la fecha actual
docker build -t $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:20251111 .
## define otro tag con la versión de nuestro software
docker build -t $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:25 .
