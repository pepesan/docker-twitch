#!/usr/bin/env bash
# Stops/removes only resources created by the selected Ansible pipeline example.
set -euo pipefail

EXAMPLE="${1:-}"
LXC_NAME="${ANSIBLE_LXC_NAME:-lxd-vm-auto}"

if [[ -z "$EXAMPLE" ]]; then
  echo "Uso: $0 70" >&2
  exit 2
fi
if ! lxc exec "$LXC_NAME" -- true >/dev/null 2>&1; then
  echo "El destino $LXC_NAME no está disponible; no se puede limpiar." >&2
  exit 1
fi

if [[ "$EXAMPLE" != "70" ]]; then
  echo "No hay limpieza automática definida para el ejemplo '$EXAMPLE'." >&2
  exit 2
fi

lxc exec "$LXC_NAME" -- bash -lc 'if systemctl cat nginx.service >/dev/null 2>&1; then systemctl stop nginx; else echo "Nginx no está instalado; nada que parar."; fi'
echo "Limpieza del ejemplo $EXAMPLE completada en $LXC_NAME."
