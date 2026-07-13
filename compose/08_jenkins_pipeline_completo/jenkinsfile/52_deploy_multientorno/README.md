# 52_deploy_multientorno

Despliegue a distintos entornos (`staging`/`producción`) elegidos por
parámetro `choice` — conecta con `04_parameters` y `06_when`. Cada entorno
usa su propio nombre de proyecto Compose (`demo-multientorno-staging` /
`-produccion`), así que ambos pueden coexistir desplegados a la vez sin
chocar entre sí, y su propio fichero `.env` (`APP_ENV`), demostrando
configuración distinta por entorno sin duplicar el `compose.yaml`.

## Cómo probarlo (por script)

```shell
./01_create.sh          # da de alta (o actualiza) el job en Jenkins
./02_build.sh            # lo lanza con el valor por defecto (staging)
./05_stop_deploy.sh              # último paso del ejercicio: para 'staging'
./05_stop_deploy.sh produccion    # y también 'produccion' si se llegó a desplegar
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # borra el job de Jenkins
```

Para lanzarlo con `ENTORNO=produccion` por script (vía API):

```shell
curl -u admin:admin -X POST \
  -H "$(curl -su admin:admin http://localhost:8082/crumbIssuer/api/json | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['crumbRequestField']+': '+d['crumb'])")" \
  --data-urlencode "ENTORNO=produccion" \
  http://localhost:8082/job/52_deploy_multientorno/buildWithParameters
```

Resultado esperado: `SUCCESS` en ambos entornos. Verificado: con
`ENTORNO=produccion` aparece además el mensaje
`ATENCION: desplegando en PRODUCCION` (la stage `when { expression {...} }`
solo se ejecuta en ese caso), y ambos entornos pueden estar desplegados **a
la vez** sin conflicto (`docker ps` los muestra como dos contenedores
distintos).

## Cómo elegir el entorno desde la consola web

1. Entra en el job: `Jenkins` → **`52_deploy_multientorno`**.
2. Menú lateral izquierdo → enlace **"Build with Parameters"** (se queda
   sin traducir, incluso con la UI en español — a diferencia de
   "Construir ahora" en un job sin parámetros).
3. Aparece un desplegable **"Entorno de despliegue"** (el texto de
   `description` del parámetro `ENTORNO` en el Jenkinsfile) con las
   opciones `staging`/`produccion` — elige una y pulsa el botón de
   construir.

Verificado: la página del formulario muestra literalmente
"Entorno de despliegue" junto al desplegable.

El despliegue **queda vivo tras el build** — mismo criterio que el resto
de la serie 50. Pararlo es un paso manual explícito:
`./05_stop_deploy.sh [staging|produccion]` (por defecto `staging` si no se
indica) — **último paso del ejercicio**, no opcional: no dejarlo para
"cuando ya no haga falta", para no acumular contenedores de pruebas
anteriores. `100_destroy.sh` también los para por si acaso (los dos
entornos), pero lo correcto es no dejarlo para el final.

## Dónde ver el despliegue vivo

```shell
docker compose -p demo-multientorno-staging ps
docker compose -p demo-multientorno-produccion ps
```

Verificado: ambos proyectos `Up` simultáneamente, cada uno con su propio
`APP_ENV` confirmado en el log de `app`.
