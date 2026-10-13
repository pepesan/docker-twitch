#!/usr/bin/env bash
# Prueba de extremo a extremo del laboratorio, desde cero:
#   destruye el entorno -> lo levanta -> aplica todas las fases -> verifica.
# Todo se registra en ./e2e.log (síguelo con: tail -f e2e.log).
# ATENCIÓN: borra los contenedores, volúmenes y docker-volume/db-data.
# Uso: ./90_e2e.sh
set -uo pipefail
cd "$(dirname "$0")"

LOG=${E2E_LOG:-$PWD/e2e.log}
exec > >(tee "$LOG") 2>&1

FAILED=()
START=$(date +%s)

step() { # descripción, comando...
  local desc=$1; shift
  echo
  echo "=== $desc ($(date +%H:%M:%S)) ==="
  if ! "$@"; then
    echo "!!! FALLO en: $desc"
    FAILED+=("$desc")
  fi
}

verify() { # fases...
  if ! ./91_e2e_verificar.sh "$@"; then
    FAILED+=("verificación: $*")
  fi
}

wait_http() { # descripción, url, intentos
  local i
  for i in $(seq 1 "${3:-60}"); do
    curl -sf -o /dev/null "$2" && return 0
    sleep 5
  done
  echo "Tiempo agotado esperando $1 ($2)"
  return 1
}

airflow_login() {
  curl -sf -X POST http://localhost:8080/auth/token -H 'Content-Type: application/json' \
    -d '{"username":"admin","password":"admin"}' -o /dev/null
}

wait_airflow() {
  local i
  for i in $(seq 1 60); do
    airflow_login && return 0
    sleep 5
  done
  echo "Tiempo agotado esperando Airflow"
  return 1
}

echo "E2E OpenMetadata + Sakila. Log: $LOG"

step "Destruir el entorno" ./99_destroy.sh
step "Levantar el stack" docker compose up -d --wait --wait-timeout 540
step "Esperar a OpenMetadata" wait_http "OpenMetadata" http://localhost:8585/api/v1/system/version 60
step "Esperar a Airflow" wait_airflow

step "06 tabla clientes" ./06_create_clientes_table.sh
step "07 ingestión de MySQL" ./07_ingest_mysql.sh
verify 07

step "08 cargar Sakila" ./08_load_sakila.sh
verify 08

for f in 09_gobierno_documentacion 10_gobierno_clasificacion 11_gobierno_glosario 12_gobierno_propiedad; do
  step "$f" "./$f.sh"
done
verify doc

step "13 calidad" ./13_gobierno_calidad.sh
verify 13

step "15 linaje desde las vistas" ./15_gobierno_linaje_vistas.sh
verify 15

step "16 tabla derivada" ./16_gobierno_linaje_derivada.sh
verify 16

step "17 almacén como servicio" ./17_gobierno_almacen_servicio.sh
verify 17

step "22 ETL real y linaje" ./22_gobierno_linaje_etl.sh
verify 22

step "21 uso de la portada" ./21_uso_todo.sh
verify uso

echo
echo "=== Verificación global ==="
./91_e2e_verificar.sh || FAILED+=("verificación global")

echo
echo "Duración: $(( ($(date +%s) - START) / 60 )) min"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "E2E: TODO CORRECTO"
else
  echo "E2E: ${#FAILED[@]} problema(s):"
  printf ' - %s\n' "${FAILED[@]}"
  exit 1
fi
