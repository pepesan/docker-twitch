#!/usr/bin/env bash
set -e

# Parar si estaba corriendo
docker compose down || true

# Crear estructura
mkdir -p source/data
mkdir -p replica/data

# Permisos (MySQL usa UID 999 en la imagen oficial)
sudo chown -R 999:999 source/data replica/data

# Permisos seguros
sudo chmod 750 source/data replica/data

echo "✔ Directorios creados y permisos configurados"

