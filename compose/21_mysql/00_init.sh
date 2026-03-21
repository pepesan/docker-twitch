#!/bin/bash

set -e

# Crear carpetas si no existen
mkdir -p data
mkdir -p conf.d

# Permisos recomendados para MySQL (UID 999 en la imagen oficial)
sudo chown -R 999:999 data

# Permisos de lectura/escritura adecuados
sudo chmod 750 data

echo "✔ Carpetas creadas y permisos configurados correctamente"

