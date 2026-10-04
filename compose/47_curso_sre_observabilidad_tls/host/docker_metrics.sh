#!/usr/bin/env bash
# ⚠ Modifica /etc/docker/daemon.json de ESTA máquina (usa sudo). Lo ejecutas
# tú; ningún otro script del laboratorio lo llama.
#
# Expone las métricas del demonio Docker (`metrics-addr`) para que Prometheus
# las recoja (job docker-daemon, ver ./15_docker_metrics.sh).
#   ./host/docker_metrics.sh                  -> 0.0.0.0:9323, SIN reiniciar Docker
#   ./host/docker_metrics.sh 0.0.0.0:9400     -> otra dirección/puerto
#   ./host/docker_metrics.sh --reiniciar      -> además reinicia Docker (ver aviso)
#   ./host/docker_metrics.sh --quitar         -> elimina metrics-addr
# Es idempotente; guarda una copia del fichero antes de cambiarlo.
#
# ⚠ AVISOS
#  * Cambiar daemon.json solo tiene efecto al REINICIAR Docker. Si no tienes
#    "live-restore": true (compruébalo: docker info | grep -i live), reiniciar
#    Docker PARA Y ARRANCA TODOS LOS CONTENEDORES de la máquina.
#  * Por qué 0.0.0.0 y no la IP de docker0: tras un reinicio del equipo docker0
#    aún no existe cuando arranca ese listener y Docker podría no arrancar.
#    Con 0.0.0.0 el puerto queda abierto a la red: restríngelo con el
#    cortafuegos (ejemplo con ufw, permitiendo solo las redes de Docker):
#       sudo ufw allow from 172.16.0.0/12 to any port 9323 proto tcp
#       sudo ufw deny 9323/tcp
set -euo pipefail

DAEMON_JSON="${DAEMON_JSON:-/etc/docker/daemon.json}"   # variable solo para poder probarlo
DIRECCION="0.0.0.0:9323"; reiniciar=0; quitar=0
for a in "$@"; do
    case "$a" in
        --reiniciar) reiniciar=1 ;;
        --quitar) quitar=1 ;;
        *) DIRECCION="$a" ;;
    esac
done

sudo_cmd=""
{ [ -w "$DAEMON_JSON" ] || { [ ! -e "$DAEMON_JSON" ] && [ -w "$(dirname "$DAEMON_JSON")" ]; }; } || sudo_cmd="sudo"

actual="$([ -e "$DAEMON_JSON" ] && $sudo_cmd cat "$DAEMON_JSON" || echo '{}')"
[ -n "$(echo "$actual" | tr -d '[:space:]')" ] || actual='{}'
nuevo="$(mktemp)"; trap 'rm -f "$nuevo"' EXIT
if ! printf '%s' "$actual" | QUITAR="$quitar" DIR="$DIRECCION" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
if os.environ["QUITAR"] == "1":
    d.pop("metrics-addr", None)
else:
    d["metrics-addr"] = os.environ["DIR"]
print(json.dumps(d, indent=2))' > "$nuevo"; then
    echo "No se pudo interpretar $DAEMON_JSON como JSON: no se toca." >&2; exit 1
fi

if [ -e "$DAEMON_JSON" ] && cmp -s "$nuevo" <(printf '%s\n' "$actual"); then
    echo "$DAEMON_JSON ya está como se pedía, sin cambios."
else
    if [ -e "$DAEMON_JSON" ]; then
        copia="$DAEMON_JSON.bak-curso-sre-$(date +%Y%m%d-%H%M%S)"
        $sudo_cmd cp -p "$DAEMON_JSON" "$copia"; echo "Copia de seguridad: $copia"
    fi
    $sudo_cmd cp "$nuevo" "$DAEMON_JSON"
    $sudo_cmd chmod 644 "$DAEMON_JSON"
    echo "Escrito $DAEMON_JSON:"; cat "$nuevo"
fi

if [ "$reiniciar" = 1 ]; then
    echo "Reiniciando Docker (esto reinicia los contenedores si no hay live-restore)..."
    sudo systemctl restart docker
    echo "Listo. Ahora: ./15_docker_metrics.sh on"
else
    echo
    echo "Falta REINICIAR Docker para que surta efecto (sudo systemctl restart docker, o"
    echo "repite con --reiniciar). Antes lee el aviso del principio de este script."
    echo "Después: ./15_docker_metrics.sh on"
fi
