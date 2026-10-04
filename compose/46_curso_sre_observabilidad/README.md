# Curso SRE + Observabilidad — laboratorio on-premise completo

Stack Docker Compose con todos los componentes usados en el curso de SRE y
Observabilidad: métricas (Prometheus + exporters + Alertmanager),
visualización (Grafana), logs centralizados (Loki + Alloy), trazas
distribuidas (Tempo) y el pipeline de instrumentación estándar
(OpenTelemetry Collector) — todo on-premise, sin depender de ningún SaaS.

Incluye además una app de demo ya instrumentada (**hot-rod**, de Jaeger) y
un generador de tráfico automático, para tener métricas/logs/trazas reales
desde el primer minuto sin tener que programar nada.

## Componentes que se arrancan

| Servicio | Rol | Bloque del temario | URL de acceso | Usuario / Password |
|---|---|---|---|---|
| `dashy` | portal unificado de acceso y comprobación de estado | Soporte general / Portal | `http://localhost:4000` | Ninguno (acceso directo) |
| `grafana` | dashboards + alertas + correlación de señales | 4. Grafana | `http://localhost:3030` | `admin` / *(generada en `compose.env` por `00_init.sh`)* |
| `prometheus` | almacena métricas, evalúa alertas, consultas PromQL | 3. Prometheus | `http://localhost:9090` | Ninguno |
| `alertmanager` | enruta y agrupa alertas de Prometheus | 3. Prometheus / 6. Incidentes | `http://localhost:9093` | Ninguno |
| `loki` | almacén central de logs estructurados | 5. Logging | `http://localhost:3100` (API) | Ninguno |
| `alloy` | recolecta y envía logs a Loki (UI de pipeline) | 5. Logging | `http://localhost:12345` (UI) | Ninguno |
| `tempo` | almacén de trazas distribuidas | 5. Trazas | `http://localhost:3200` (API) | Ninguno |
| `otel-collector` | pipeline único OTLP (trazas, métricas y logs) | 2. OTel | `http://localhost:8889/metrics` | Ninguno |
| `hotrod` | app de demostración instrumentada con OTel | 2. OTel / 5. Trazas | `http://localhost:8082` | Ninguno |
| `node-exporter` | métricas de CPU, RAM, disco y red del host | 3. Prometheus | `http://localhost:9100/metrics` | Ninguno |
| `blackbox-exporter` | comprobación de disponibilidad HTTP de endpoints | 3. Prometheus | `http://localhost:9115` | Ninguno |
| `caddy` | adapta los enlaces `Find trace` de HotROD (búsqueda por tag `driver` o traza por ID) a Grafana/Tempo | Soporte para trazas | `http://localhost:16686` | Ninguno |
| `load-generator` | genera tráfico sintético continuo hacia hot-rod | Soporte para talleres | *(proceso interno en bucle)* | Sin interfaz |

No hay imagen "de aplicación propia" que instrumentar a mano en clase: se
puede usar `hotrod` como caso ya resuelto para explorar Grafana/Tempo/Loki,
y como referencia de instrumentación OTel real (ver sus logs de arranque).

## Diagrama de flujo de datos

Cómo circula cada tipo de señal (métricas, logs, trazas) entre los
contenedores, de la fuente hasta Grafana:

```mermaid
flowchart LR
    subgraph Demo["App de demo"]
        LG[load-generator] -->|tráfico HTTP| HR[hotrod]
    end

    subgraph Metricas["Métricas"]
        NE[node-exporter] -->|expone /metrics| PROM[Prometheus]
        BB[blackbox-exporter] -->|probe HTTP a hotrod/grafana| PROM
        PROM -->|reglas de alerta| AM[Alertmanager]
    end

    subgraph OTel["Instrumentación OTel"]
        HR -->|traces + métricas OTLP/HTTP :4318| OTC[OTel Collector]
        OTC -->|traces OTLP/gRPC| TEMPO[Tempo]
        OTC -->|métricas expuestas :8889| PROM
    end

    subgraph Logs["Logs"]
        PT[Alloy] -->|lee docker.sock + /var/lib/docker/containers| ALLCTR[logs de TODOS los contenedores]
        PT -->|push| LOKI[Loki]
        OTC -.->|logs OTLP/HTTP opcional| LOKI
    end

    subgraph Visualizacion["Grafana"]
        PROM -->|datasource| GRAF[Grafana]
        LOKI -->|datasource| GRAF
        TEMPO -->|datasource + correlación| GRAF
        AM -.->|Alerting UI| GRAF
    end

    GRAF -->|dashboard provisionado| USR([Alumno/instructor])
```

- Las **flechas continuas** son el flujo normal en marcha desde el arranque.
- La flecha punteada `OTC -.-> LOKI` es el camino opcional para logs enviados
  directamente por OTLP (en vez de vía Alloy) si en algún taller se
  instrumenta una app propia.
- `blackbox-exporter` no scrapea nada por sí mismo: Prometheus le pide
  "compruébame esta URL" (`http://hotrod:8080`, `http://grafana:3000/login`)
  y él hace el `GET` y devuelve `probe_success`.

## Primeros pasos

```bash
cd compose/46_curso_sre_observabilidad
./00_init.sh            # (solo la primera vez) crea carpetas de datos y compose.env con password de Grafana
./01_launch_compose.sh   # levantar todo
./02_ps_compose.sh       # ver estado
./03_logs_compose.sh [servicio]  # ver logs (por defecto todos)
./04_exec_compose.sh <servicio> [comando]  # shell dentro de un contenedor (sh por defecto)
./05_stop_compose.sh     # parar (sin borrar datos)
./06_start_compose.sh    # volver a arrancar tras un stop
./20_destroy.sh          # borrar TODO (contenedores + datos + compose.env), pide confirmación
```

## URLs de acceso

- **Portal (Dashy)**: http://localhost:4000 — portal central con enlaces y comprobaciones de estado de todos los servicios del laboratorio
- **Grafana**: http://localhost:3030 (usuario `admin`, password generada por `00_init.sh` — ver `compose.env` o la salida de `01_launch_compose.sh`)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **Loki API**: http://localhost:3100 (sin UI propia, se consulta desde Grafana)
- **Alloy UI**: http://localhost:12345 (grafo del pipeline de logs y estado de sus componentes)
- **Tempo API**: http://localhost:3200 (sin UI propia, se consulta desde Grafana)
- **Blackbox Exporter**: http://localhost:9115
- **hot-rod (demo app)**: http://localhost:8082 — cuatro botones de cliente (Rachel's Floral Designs, Trom Chocolatier, Japanese Desserts y Amazing Coffee Roasters); cada clic genera una petición y una traza distribuida

Grafana ya trae provisionados (sin tocar nada) los datasources de
Prometheus, Loki y Tempo, con la correlación activada: desde una traza en
Tempo puedes saltar a los logs de ese mismo periodo en Loki, y desde ahí a
las métricas en Prometheus (bloque 5, "Correlación de señales").

## Dashboards de la comunidad

Grafana trae provisionados siete dashboards de [grafana.com](https://grafana.com/grafana/dashboards/),
reutilizados en vez de hechos a mano, más el dashboard propio **Infraestructura
- Node Exporter**. Todos usan los datasources internos (`prometheus`, `loki`,
`tempo`, con uid fijo) y se han **verificado ejecutando cada consulta contra
los datos reales** de un arranque desde cero.

| Dashboard | ID en grafana.com | Para qué sirve | Quitado por no ser aplicable |
|---|---|---|---|
| Node Exporter Full | [1860](https://grafana.com/grafana/dashboards/1860) | host: CPU, RAM, disco, red, procesos, TCP | 4 paneles de *systemd* (AppArmor de Docker bloquea el colector), *IRQ Detail* (el kernel no da datos) y *Power Supply* / *Hardware Fan Speed* (hardware) |
| Prometheus | [19105](https://grafana.com/grafana/dashboards/19105) | salud del propio Prometheus | 5 paneles de Kubernetes (pods, volúmenes persistentes) |
| Prometheus Blackbox Exporter | [7587](https://grafana.com/grafana/dashboards/7587) | disponibilidad y latencia de endpoints | *SSL Expiry* (las sondas son HTTP, sin TLS) |
| Alertmanager | [9578](https://grafana.com/grafana/dashboards/9578) | alertas, silencios, notificaciones | 5 paneles de *gossip* de cluster y *duración de notificaciones* (un solo nodo y receptor sin integraciones) |
| Logs / App | [13639](https://grafana.com/grafana/dashboards/13639) | logs por aplicación (Loki, etiqueta `job` = `proyecto/servicio`) | — |
| OpenTelemetry Collector | [15983](https://grafana.com/grafana/dashboards/15983) | flujo de spans por el collector (sus métricas internas, `:8888`) | 27 paneles de métricas/logs OTLP, RPC/HTTP y Kubernetes (aquí solo pasan trazas) |
| Span Metric Service Performance | [21202](https://grafana.com/grafana/dashboards/21202) | RED (tasa, errores, latencia) por servicio de hot-rod, a partir de las span metrics de Tempo | — |

Para que estos dashboards tengan datos, el stack incluye lo que esperan:
Alertmanager y las métricas internas del collector (`:8888`) como targets de
Prometheus, la etiqueta `job` (convención `proyecto/servicio`) en los logs que
envía Alloy y la etiqueta `service` en las span metrics de Tempo 2.x.

**Paneles que pueden salir vacíos y es normal** (no hay nada que mostrar, no
es un fallo): *Instance Down* (Prometheus, si no cae ningún target), *TCP
Stat Transient* (Node Exporter, sin conexiones en esos estados) y varios
histogramas de mantenimiento de Alertmanager (snapshots y GC periódicos, cada
~15 min). En *OpenTelemetry Collector*, el selector **exporter** debe estar
en `otlp/tempo` para ver los spans exportados.

**Añadir o actualizar uno**: descárgalo de grafana.com y normalízalo con
`tools/importar_dashboard.py` (sustituye los datasources por los uid del
stack y puede quitar paneles). Compruébalo con
`tools/verificar_dashboard.py config/grafana/dashboards/<fichero>.json`, que
resuelve las variables contra Prometheus/Loki y ejecuta cada consulta
(el stack debe estar levantado); avisa de los paneles sin datos.


## Cómo ver todo esto en Grafana (guía rápida)

Todo llega ya conectado (datasources + dashboard provisionados), pero conviene
saber dónde mirar cada cosa la primera vez que entras:

1. **Dashboards** — menú lateral **Dashboards** → carpeta **Curso SRE**. Hay
   ocho: el propio **Infraestructura - Node Exporter** y siete de la comunidad
   (grafana.com), provisionados desde `config/grafana/dashboards/`; ver
   "Dashboards de la comunidad" más arriba para qué hace cada uno. Si algún
   panel aparece vacío, casi siempre es el selector de rango de tiempo
   (arriba a la derecha) — pon **Last 15 minutes** si el stack lleva poco
   arriba.

2. **Métricas sueltas (PromQL)** — menú **Explore**, datasource **Prometheus**
   (selector arriba a la izquierda del panel). Escribe una métrica, por
   ejemplo `up`, y pulsa **Run query** (botón azul arriba a la derecha, o
   `Shift+Enter` con el cursor en el editor) — Grafana no ejecuta la consulta
   solo con escribirla.

3. **Logs (LogQL)** — **Explore** → datasource **Loki** → query
   `{container="hotrod"}`. Cada línea de log de `hotrod` incluye su
   `trace_id`, clave para el paso 5.
   - Alternativa sin escribir LogQL a mano: menú **Drilldown → Logs**
     (`/drilldown`), elige datasource Loki y te lista los `container`
     disponibles (`hotrod`, `grafana`, `prometheus`, `otel-collector`...)
     para ir filtrando a clics.

4. **Trazas** — **Explore** → datasource **Tempo** → pestaña **Search** →
   filtra por `Service Name = frontend` (o pega un `trace_id` visto en Loki).
   Verás el árbol de spans de una petición real de `hotrod`.

5. **Correlación traza → log → métrica** — abre una traza en Tempo, cada span
   tiene un botón **Logs for this span** que te lleva directo a Loki filtrado
   por ese `trace_id` y esa ventana de tiempo exacta (bloque 5 del temario,
   "Correlación de señales").

## Cómo mapear cada taller del temario a este entorno

### Bloque 3 — Prometheus
- Arquitectura ya desplegada: `prometheus` + `node-exporter` (sistema) +
  `blackbox-exporter` (endpoints) + `alertmanager`.
- PromQL: usar la pestaña **Explore** de Prometheus o Grafana contra
  `node_cpu_seconds_total`, `node_memory_MemAvailable_bytes`, `probe_success`, etc.
- Reglas de alerta ya definidas en `config/alert_rules.yml` (instancia caída,
  CPU alta, disco casi lleno, endpoint caído) — puedes dispararlas en clase
  parando `node-exporter` (`docker compose stop node-exporter`) o generando
  carga de CPU en el host.
- Enrutado en `config/alertmanager.yml` (receiver `default`; hay ejemplos
  comentados de webhook/email/Slack para configurar en el taller).

### Bloque 4 — Grafana
- Datasource Prometheus ya conectado.
- Dashboard de referencia ya provisionado: **Curso SRE → Infraestructura -
  Node Exporter** (CPU, memoria, disco, red, disponibilidad de endpoints) —
  úsalo como punto de partida y pide a los alumnos que añadan paneles nuevos
  (p.ej. tasa de peticiones/errores de `hotrod` vía sus métricas OTel).
- Canales de notificación: **Alerting → Contact points** en la propia UI de
  Grafana (email/Slack/webhook), independientes de los de Alertmanager.

### Bloque 5 — Logging y Trazas
- Loki + Alloy ya recolectan **los logs de todos los contenedores de este
  mismo compose** (etiquetados por nombre de contenedor) — en Grafana, pestaña
  **Explore → Loki**, prueba `{container="hotrod"}`.
- LogQL: filtra por label, por texto (`|= "error"`), agrega con
  `count_over_time(...)`.
- Trazas: entra en http://localhost:8082 y pulsa uno de los cuatro botones de
  cliente. Cada acción genera una petición; el enlace **find trace** abre
  Grafana → **Explore → Tempo** filtrando por el evento `driver`, mientras
  **open trace** abre directamente el ID de esa petición en Tempo. Grafana
  solicita autenticación si aún no has iniciado sesión.
- Taller de correlación: parte de una traza lenta en Tempo → botón "Logs for
  this span" → aterrizas en Loki filtrado a ese `trace_id` y esa ventana de
  tiempo exacta.

### Bloque 6 — Gestión de incidentes
- Simulación de incidente: parar `node-exporter` o `hotrod`
  (`docker compose stop hotrod`) dispara `InstanceDown`/`EndpointNoResponde`
  en Prometheus → aparece en Alertmanager (http://localhost:9093) → se puede
  ver también en Grafana Alerting.
- Practicar el ciclo completo: detección (alerta) → clasificación (severity
  del `alert_rules.yml`) → respuesta (`docker compose start <servicio>`) →
  redacción de post-mortem con las capturas de Grafana/Prometheus/Alertmanager
  como evidencia (MTTD = hora de la alerta - hora del corte real; MTTR = hora
  de vuelta a verde - hora de la alerta).

## Notas de la instalación

- Todos los datos persistentes son bind mounts locales, unificados bajo
  `./volumes/<servicio>/data` (`volumes/prometheus/data`,
  `volumes/alertmanager/data`, `volumes/loki/data`, `volumes/tempo/data`,
  `volumes/grafana/data`) — no volúmenes con nombre. Una carpeta por
  servicio y, dentro, una por cada volumen que necesite (de momento todos
  tienen solo `data`, pero deja sitio para añadir más si algún servicio lo
  necesitara).
- `otel-collector` usa la imagen `-contrib` (no la mínima) porque el
  exporter de Loki solo está en esa variante.
- `alloy` (Grafana Alloy, sustituto oficial de Promtail, fin de vida el
  2-mar-2026) necesita acceso al socket de Docker (`/var/run/docker.sock`,
  solo lectura) para descubrir los contenedores vía `discovery.docker` —
  sin eso no encuentra ningún log. Su configuración está en
  `config/config.alloy` y mantiene las etiquetas `container`, `stream` y
  `job="syslog"`. Su UI (grafo del pipeline y estado de cada componente)
  está publicada en http://localhost:12345, útil para depurar en clase.
- `hotrod` se lanza con `--otel-exporter=otlp` apuntando al puerto **HTTP**
  del collector (`OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318`,
  `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`) — apunta por defecto al de
  gRPC (4317) y el handshake falla con "malformed HTTP response". Si tu
  versión de la imagen cambia este comportamiento, revisa sus logs de
  arranque (`./03_logs_compose.sh hotrod`) y ajusta el `command:`/`environment:`
  en `compose.yaml`.
- Se fija `tempo:2.6.1` (no `latest`) porque Tempo 3.x rehízo la
  configuración monolítica (`ingester`/`compactor` sustituidos por
  `backend-scheduler`/`block-builder`) y rompe `config/tempo.yaml`.
- Todos los puertos quedan publicados en el host (no hay red aislada) para
  poder acceder a cada UI directamente durante las clases; en un despliegue
  real del CPD, limita esto con firewall/reverse proxy según corresponda.
