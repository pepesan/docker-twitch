#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=app-python
# Definir la versión del Tag
DOCKER_HUB_TAG=1.0.1-3.12
# crear el contenedor en base la imagen al Docker hub
## push es el comando principal
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
## -d ejecuta el contenedor en modo daemon
## -p redirecciona el puerto 8080 del host al 8080 de contenedor
## -v el directorio del host ./webapps se asocia al /deploy/tomcat/webapps del contenedor
docker run \
 --rm \
 --name app-python \
 $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:$DOCKER_HUB_TAG

