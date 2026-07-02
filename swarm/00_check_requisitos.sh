#!/usr/bin/env bash
# Comprueba que el host tiene lo mínimo para levantar el laboratorio: LXD, la
# imagen base con la clave SSH ya incluida, y la red gestionada donde vivirán
# los 5 nodos. No crea nada, solo valida.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

fail=0

if ! command -v lxc &>/dev/null; then
  echo "ERROR: falta el comando 'lxc' (LXD)" >&2
  fail=1
fi

if ! lxc image list -f csv -c l 2>/dev/null | grep -qx "$IMAGE"; then
  echo "ERROR: no existe la imagen local '$IMAGE' (ver: lxc image list)" >&2
  fail=1
fi

if ! lxc network list -f csv 2>/dev/null | cut -d, -f1 | grep -qx "$NETWORK"; then
  echo "ERROR: no existe la red '$NETWORK' (ver: lxc network list)" >&2
  fail=1
fi

if [ "$fail" -eq 1 ]; then
  exit 1
fi

echo "==> Requisitos OK: LXD, imagen '$IMAGE' y red '$NETWORK' disponibles."
