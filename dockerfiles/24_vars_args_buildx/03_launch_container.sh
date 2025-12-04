#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=alpine-var-arg-param

docker run --rm  $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:latest
