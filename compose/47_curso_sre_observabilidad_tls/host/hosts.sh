#!/usr/bin/env bash
# ⚠ Modifica /etc/hosts de ESTA máquina (usa sudo). Lo ejecutas tú; ningún
# otro script del laboratorio lo llama.
#
# Añade (o sustituye) un bloque con los nombres *.lab.local de Caddy:
#   ./host/hosts.sh            -> apuntan a 127.0.0.1
#   ./host/hosts.sh 10.0.0.5   -> apuntan a esa IP (stack en otra máquina)
#   ./host/hosts.sh --quitar   -> elimina el bloque
# Es idempotente: ejecutarlo varias veces deja un único bloque.
set -euo pipefail

HOSTS_FILE="${HOSTS_FILE:-/etc/hosts}"     # variable solo para poder probarlo
BEGIN="# BEGIN curso-sre-lab"
END="# END curso-sre-lab"
NOMBRES=(grafana prometheus alertmanager loki tempo hotrod demo-app alloy portal)

accion="poner"; ip="127.0.0.1"
case "${1:-}" in
    --quitar) accion="quitar" ;;
    "") ;;
    *) ip="$1" ;;
esac

sudo_cmd=""
[ -w "$HOSTS_FILE" ] || sudo_cmd="sudo"

nuevo="$(mktemp)"
trap 'rm -f "$nuevo"' EXIT
# el contenido actual sin nuestro bloque
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$HOSTS_FILE" > "$nuevo"

if [ "$accion" = "poner" ]; then
    {
        echo "$BEGIN"
        printf '%s' "$ip"
        for n in "${NOMBRES[@]}"; do printf ' %s.lab.local' "$n"; done
        echo
        echo "$END"
    } >> "$nuevo"
fi

$sudo_cmd cp "$nuevo" "$HOSTS_FILE"
if [ "$accion" = "poner" ]; then
    echo "Hecho. $HOSTS_FILE contiene ahora:"
    sed -n "/^$BEGIN\$/,/^$END\$/p" "$HOSTS_FILE"
else
    echo "Hecho. Bloque curso-sre-lab eliminado de $HOSTS_FILE."
fi
