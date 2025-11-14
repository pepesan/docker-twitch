#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre del repositorio
REPO_NAME=my-app-react-precompiled
# construir la imagen en base al Dockerfile
## build es el comando principal
## -t define el tag asociado a la imagen
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
## . pilla el Dockerfile que hay en el directorio actual
docker build --no-cache -t $DOCKER_HUB_USER/$REPO_NAME:latest -f ./Dockerfile.precompiled .
## define otro tag con la fecha actual
docker build -t $DOCKER_HUB_USER/$REPO_NAME:20251111 -f ./Dockerfile.precompiled .
## define otro tag con la versión de nuestro software
docker build -t $DOCKER_HUB_USER/$REPO_NAME:1.0.0 -f ./Dockerfile.precompiled .
