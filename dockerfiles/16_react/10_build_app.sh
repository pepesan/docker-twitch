#!/bin/bash

## Configuración del entorno
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Carga nvm

nvm install 24
nvm use 24

## Actualiza npm a la última versión
echo "Actualizando npm a la última versión..."
npm install -g npm@latest

## Descarga las dependencias necesarias
echo "Descargando dependencias..."
npm ci --silent

## Construye la aplicación para producción
echo "Construyendo la aplicación para producción..."
npm run build