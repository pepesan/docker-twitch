#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=debian-vol

mkdir -p /home/$USER/midir

docker run --rm -it  -v /home/$USER/midir:/myvol:rw  $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:latest bash
