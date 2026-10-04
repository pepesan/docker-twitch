#!/usr/bin/env bash
# Deja el directorio como recién clonado: borra contenedores, red, todos los
# datos (./volumes), las credenciales generadas (compose.env, caddy.env) y la
# CA raíz (./pki). Irreversible. No toca tu máquina (/etc/hosts, CA instalada
# en el sistema o en el navegador): eso lo retiras con host/*.sh --quitar.
cd "$(dirname "$0")"
read -r -p "Esto borrará los contenedores, TODOS los datos (métricas, logs, trazas, dashboards), compose.env, caddy.env y la CA raíz (pki/). ¿Continuar? [y/N] " confirmacion
if [[ "$confirmacion" =~ ^[yY]$ ]]; then
    # `down` necesita que existan los env_file del compose; si el entorno está
    # a medias (alguno ya borrado) se crean vacíos para poder limpiarlo igual.
    [ -f compose.env ] || : > compose.env
    [ -f caddy.env ] || : > caddy.env
    docker compose --env-file compose.env down -v --remove-orphans
    sudo rm -rf volumes
    rm -f compose.env caddy.env
    rm -rf pki
    echo "Entorno limpio. La CA raíz también se ha borrado: tras 00_init.sh habrá una nueva."
    echo "Si la instalaste en tu máquina, sustitúyela con host/instalar_ca.sh (o retírala con --quitar)."
else
    echo "Cancelado."
fi
