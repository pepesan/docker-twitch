#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=debian-vol
# Antes de hacer el push hay que hacer el login
# el docker hub
## pedirá usuario y contraseña
# docker login -u $DOCKER_HUB_USER
# subir la imagen al Docker hub
## push es el comando principal
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
docker push $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:latest
## define otro tag con la fecha actual
docker push $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:20251204