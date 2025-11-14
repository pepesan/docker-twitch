#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre del repositorio
REPO_NAME=my-app-react-precompiled

# ejecutar la imagen
docker run -d --name react-app -p 81:80 $DOCKER_HUB_USER/$REPO_NAME:latest
