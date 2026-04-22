#!/bin/bash

echo "Creando estructura de directorios..."

# Carpeta para salida de datos
mkdir -p ./output

echo "Ajustando permisos..."

# NiFi dentro del contenedor usa UID 1000 normalmente
chown -R 1000:1000 ./output

# Permisos básicos de escritura
chmod -R 755 ./output

echo "Estructura lista"



