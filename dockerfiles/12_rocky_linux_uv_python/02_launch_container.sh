#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=app-python-uv
# Definir la versión del Tag
DOCKER_HUB_TAG=1.1.3-3.14
# crear el contenedor en base la imagen al Docker hub
## push es el comando principal
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
docker run \
 --name app-python-uv \
 --rm \
 $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:$DOCKER_HUB_TAG

