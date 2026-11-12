# Monitorización local HTTP

Alloy, Prometheus y Loki permanecen en la red interna `observability`. Grafana también usa la red bridge dedicada `grafana_frontend`: en el Docker Engine probado, el puerto publicado no se aplicó cuando Grafana solo estaba conectado a una red `internal`. Esta red permite salida desde Grafana, pero no se comparte con los demás ejemplos; el único puerto publicado sigue siendo `127.0.0.1:3300`.

Esta es la versión **sin TLS**. La versión TLS/mTLS numerada inmediatamente después está en [`../54_monitoring_tls/README.md`](../54_monitoring_tls/README.md).

## Ficheros

- `compose.yaml`: servicios versionados, persistencia y red interna.
- `alloy/config.alloy`: exporter Unix y lectura explícita de `dpkg.log`.
- `prometheus/prometheus.yml`, `loki/loki.yml`: configuración de métricas y logs.
- `grafana/provisioning/`: datasources Prometheus/Loki y dashboards.
- `grafana/dashboards/host-overview.json`: dashboard de host.
- `.env.example`: variables de configuración; `.gitignore` excluye credenciales y datos.

## Paso a paso

Ejecuta los scripts desde esta carpeta, en orden:

1. `./00_init.sh` — crea `.env` local con contraseña aleatoria si no existe y prepara `data/alloy`. Conserva un `.env` existente.
2. `./01_launch_compose.sh` — valida con `docker compose config -q` y arranca la pila.
3. `./02_ps_compose.sh` — muestra el estado; Grafana: <http://127.0.0.1:3300> (usuario `admin`, contraseña en `.env`).
4. `./03_logs_compose.sh [servicio]` — sigue todos los logs o los de un servicio, por ejemplo `./03_logs_compose.sh alloy` (Ctrl-C termina el seguimiento).
5. `./04_exec_compose.sh SERVICIO COMANDO...` — ejecuta un comando en el contenedor, por ejemplo `./04_exec_compose.sh prometheus promtool --version`.
6. `./05_stop_compose.sh` — detiene sin borrar contenedores ni datos.
7. `./06_start_compose.sh` — reanuda los contenedores detenidos.
8. `./99_destroy.sh` — destrucción irreversible, solicita escribir `DESTROY`; borra contenedores, red, volúmenes Docker, `data/alloy` y `.env`.

`00_init.sh` es requisito previo del primer arranque. `99_destroy.sh` borra la configuración local; para volver a desplegar empieza otra vez por `00_init.sh`. No ejecutes esta versión y la variante TLS al mismo tiempo.

## Variables y comprobación

`00_init.sh` fija automáticamente `HOST_LABEL=$(hostname)`, `ALLOY_UID=$(id -u)`, `ALLOY_GID=$(id -g)` y crea `GRAFANA_ADMIN_PASSWORD` aleatoria. Si necesitas cambiar `HOST_LABEL` o UID/GID, edita `.env` antes del arranque; no publiques ese fichero.

Prometheus y Loki no publican puertos al host. Comprueba muestras y provisioning:

```sh
set -a; . ./.env; set +a
./04_exec_compose.sh prometheus promtool query instant http://localhost:9090 "up{host=\"$HOST_LABEL\",job=\"alloy/unix\"}"
./04_exec_compose.sh prometheus promtool query instant http://localhost:9090 "node_memory_MemAvailable_bytes{host=\"$HOST_LABEL\"}"
curl -fsS -u "admin:$GRAFANA_ADMIN_PASSWORD" http://127.0.0.1:3300/api/datasources
curl -fsS -u "admin:$GRAFANA_ADMIN_PASSWORD" 'http://127.0.0.1:3300/api/search?query=Host%20overview'
```

LogQL desde un contenedor curl temporal conectado a la red interna:

```sh
set -a; . ./.env; set +a
docker run --rm --network docker-twitch-monitoring_observability curlimages/curl:8.16.0 \
  --fail --silent --show-error --get \
  --data-urlencode "query={host=\"$HOST_LABEL\",service=\"package-manager\"}" \
  --data-urlencode 'since=24h' --data-urlencode 'limit=10' \
  http://loki:3100/loki/api/v1/query_range
```

El `up` de Alloy debe ser `1`; la consulta a Loki busca las etiquetas `host` y `service=package-manager`. En `02_ps_compose.sh`, solo Grafana debe mostrar publicación local de puerto.

No hay acceso remoto habilitado. Para usar HTTPS con autenticación mTLS, sigue el ejemplo separado `54_monitoring_tls`; no reutilices estos certificados de laboratorio en producción.
