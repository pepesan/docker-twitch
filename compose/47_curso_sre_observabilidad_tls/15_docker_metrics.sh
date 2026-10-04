#!/usr/bin/env bash
# Activa/desactiva el scrape de las métricas del demonio Docker del host.
#   ./15_docker_metrics.sh on [puerto]   (por defecto 9323)
#   ./15_docker_metrics.sh off
# Solo escribe config/targets/docker-daemon.yml (Prometheus lo relee solo).
# NO toca el host: antes hay que exponer las métricas en el demonio con
# ./host/docker_metrics.sh (lo ejecutas tú; ver README).
set -euo pipefail
cd "$(dirname "$0")"
fichero="config/targets/docker-daemon.yml"

case "${1:-}" in
    on)
        puerto="${2:-9323}"
        cat > "$fichero" <<YAML
# Generado por 15_docker_metrics.sh (on). host.docker.internal = host Docker
- targets: ['host.docker.internal:${puerto}']
  labels:
    host: '$(hostname)'
YAML
        echo "Scrape del demonio Docker ACTIVADO en host.docker.internal:${puerto}."
        echo "Si aún no lo has hecho, expón las métricas en el host: ./host/docker_metrics.sh"
        echo "Comprobación: Prometheus → Status → Targets → docker-daemon (debe estar UP)."
        ;;
    off)
        cat > "$fichero" <<'YAML'
# Desactivado por 15_docker_metrics.sh (off).
[]
YAML
        echo "Scrape del demonio Docker DESACTIVADO."
        ;;
    *)
        echo "Uso: $0 on [puerto] | off" >&2; exit 1 ;;
esac
