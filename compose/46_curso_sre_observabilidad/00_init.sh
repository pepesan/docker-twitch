#!/usr/bin/env bash
# Crea las carpetas de datos persistentes y genera compose.env con una
# contraseña de Grafana nueva (a partir de compose.env.template) si no existe
# todavía. Ejecutar una vez antes del primer 01_launch_compose.sh y cada vez
# que se borre con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p volumes/prometheus/data volumes/alertmanager/data volumes/loki/data volumes/alloy/data volumes/tempo/data volumes/grafana/data
# Prometheus, Grafana, Loki y Tempo corren dentro del contenedor con un UID
# no-root distinto cada uno; en vez de averiguar y encajar cada UID, se abre
# el directorio para que cualquiera pueda escribir (aceptable en un
# laboratorio local, no en un despliegue real del CPD).
chmod -R 777 volumes

if [ -f compose.env ]; then
    echo "compose.env ya existe, no se regenera (borra el fichero si quieres una password nueva)."
else
    admin_password=$(openssl rand -hex 12)
    sed -e "s/__GRAFANA_ADMIN_PASSWORD__/${admin_password}/" \
        compose.env.template > compose.env
    echo "compose.env generado. Credenciales iniciales de Grafana:"
    echo "  usuario:  admin"
    echo "  password: ${admin_password}"
fi
