#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan

# ejecutar la imagen
docker run --rm $DOCKER_HUB_USER/docker-cowsay:latest