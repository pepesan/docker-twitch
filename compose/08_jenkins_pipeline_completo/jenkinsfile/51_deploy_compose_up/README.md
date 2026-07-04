# 51_deploy_compose_up

Despliegue de una app multicontenedor (`app` + `db`) con
`docker compose up -d`, referenciando un `compose.yaml` escrito en el
propio workspace — conecta con lo visto en la unidad de Stacks (Docker
Compose), ahora disparado desde Jenkins. `app` depende de que `db` esté
**saludable** (`depends_on: condition: service_healthy`), no solo
arrancada — se verifica comprobando que `app` solo escribe su mensaje una
vez que Compose ha esperado el healthcheck de `db`.

## Cómo probarlo

```shell
./01_create.sh      # da de alta (o actualiza) el job en Jenkins
./02_build.sh        # lo lanza y espera el resultado
./02_build.sh        # relanzarlo es idempotente (docker compose up -d)
./04_stop_deploy.sh  # último paso del ejercicio: para el despliegue de prueba
./03_delete.sh       # borra el job de Jenkins
```

Resultado esperado: `SUCCESS`. Verificado en consola:

```
Container demo-compose-app-db-1  Waiting
Container demo-compose-app-db-1  Healthy
Container demo-compose-app-app-1  Starting
...
app confirmo que la base de datos estaba healthy antes de arrancar
```

El despliegue **queda vivo tras el build** — mismo criterio que
`33_build_publish_deploy`/`50_deploy_docker_run`. Pararlo es un paso
manual explícito: `./04_stop_deploy.sh` (localiza por el label de Compose
`com.docker.compose.project=demo-compose-app`, sin necesitar el
`compose.yaml`, que solo existe dentro del workspace del job) —
**último paso del ejercicio**, no opcional: no dejarlo para "cuando ya no
haga falta", para no acumular contenedores de pruebas anteriores.
`100_destroy.sh` también lo para por si acaso, pero lo correcto es no
dejarlo para el final.

## Dónde ver el despliegue vivo

```shell
docker compose -p demo-compose-app ps
```

Verificado: `db` en estado `healthy`, `app` en `Up`.
