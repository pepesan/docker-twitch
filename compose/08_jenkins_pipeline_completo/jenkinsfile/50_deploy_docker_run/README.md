# 50_deploy_docker_run

Despliegue simple con `docker run -d`: construye una imagen y la despliega
como un contenedor con nombre fijo (`demo-run-app`), parando y sustituyendo
el contenedor anterior si ya existe — **idempotente**: relanzar el build
no acumula contenedores ni falla por `Conflict. The container name ...
is already in use`.

## Cómo probarlo

```shell
./01_create.sh      # da de alta (o actualiza) el job en Jenkins
./02_build.sh       # lo lanza y espera el resultado
./02_build.sh       # relanzarlo sustituye el contenedor, no falla
./05_stop_deploy.sh # último paso del ejercicio: para el despliegue de prueba
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # borra el job de Jenkins
```

Resultado esperado: `SUCCESS` en ambos builds. Verificado: el segundo
build reemplaza el contenedor (nueva imagen `demo-run-app:<BUILD_NUMBER>`,
`Up 2 seconds`), no lo acumula.

El despliegue (`docker run -d --name demo-run-app`) **queda vivo tras el
build** — mismo criterio que `33_build_publish_deploy`: un deploy que se
autodestruye al terminar no tendría sentido. Pararlo es un paso manual
explícito: `./05_stop_deploy.sh` — **último paso del ejercicio**, no
opcional: no dejarlo para "cuando ya no haga falta", para no acumular
contenedores de pruebas anteriores. `100_destroy.sh` también lo para por
si acaso, pero lo correcto es no dejarlo para el final.

## Dónde ver el despliegue vivo

```shell
docker ps --filter name=demo-run-app --format '{{.Names}}\t{{.Status}}\t{{.Image}}'
docker logs demo-run-app
```

Verificado: contenedor `Up`, logs mostrando "vivo desde hace Ns" cada 10s.
