#!/bin/bash
# definir el usuario de dockerhub
DOCKER_HUB_USER=pepesan
# Definir el nombre de la imagen o repositorio
DOCKER_HUB_REPOSITORY=debian-var-arg-param-buildx
# construir la imagen en base al Dockerfile
## build es el comando principal
## -t define el tag asociado a la imagen
## tag: usuario/repositorio:tag
## tag: usuario/nombre_imagen:tag
## . pilla el Dockerfile que hay en el directorio actual

# Cargar las variables del .env en el entorno actual
export $(grep -v '^#' .env | xargs)


# Usarlas como build-args
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg APP_MODE \
  --build-arg API_URL \
  --push  \
  -t $DOCKER_HUB_USER/$DOCKER_HUB_REPOSITORY:latest \
  .