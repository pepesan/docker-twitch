#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# construir la imagen en base al Dockerfile
## build es el comando principal
## -t define el tag asociado a la imagen
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
## . pilla el Dockerfile que hay en el directorio actual
docker build -t $DOCKER_HUB_USER/docker-cowsay:latest .
## define otro tag con la fecha actual
docker build -t $DOCKER_HUB_USER/docker-cowsay:20251204 .
## define otro tag con la versión de nuestro software
docker build -t $DOCKER_HUB_USER/docker-cowsay:1.0.0 .
