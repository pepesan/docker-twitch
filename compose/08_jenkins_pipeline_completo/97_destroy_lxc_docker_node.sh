#!/usr/bin/env bash
# Script 97: Elimina el contenedor LXC generado para la nube externa de Docker.
set -euo pipefail

NODE_NAME="jenkins-external-docker"

echo "==> Iniciando destrucción del nodo LXC: $NODE_NAME"

if lxc info "$NODE_NAME" &>/dev/null; then
  echo "    [-] Deteniendo el contenedor LXC '$NODE_NAME'..."
  lxc stop "$NODE_NAME" --force || true

  echo "    [-] Eliminando el contenedor LXC '$NODE_NAME'..."
  lxc delete "$NODE_NAME"

  # Limpiar archivo temporal de variables si existe
  ENV_FILE=".env.remote-docker"
  if [ -f "$ENV_FILE" ]; then
    rm -f "$ENV_FILE"
    echo "    [-] Eliminado archivo temporal '$ENV_FILE'"
  fi

  echo "    [OK] Contenedor LXC '$NODE_NAME' eliminado correctamente."
else
  echo "    [!] El contenedor LXC '$NODE_NAME' no existe. Nada que hacer."
fi
