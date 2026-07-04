# 33_build_publish_deploy

Cierre de ciclo de la serie 30: construye la imagen real de
`spring-boot-30-demo-maven` (usa su propio Dockerfile), la publica en
Nexus, y la despliega con `docker compose up`, comprobando que arranca de
verdad (`/actuator/health`) — puente directo hacia el pipeline real (`90+`).

## Cómo probarlo

```shell
./01_create.sh          # da de alta (o actualiza) el job en Jenkins
./02_build.sh           # lo lanza y espera el resultado
./04_stop_deploy.sh     # último paso del ejercicio: para el despliegue de prueba
./05_approve_destroy.sh # alternativa: lo destruye desde el propio pipeline (ver más abajo)
./03_delete.sh          # borra el job de Jenkins
```

**Requiere Nexus levantado y configurado** (`./08_launch_nexus.sh` +
`./09_setup_nexus.sh` desde la carpeta principal de `compose/`).

El despliegue (`docker compose -p demo-deploy up -d`) **queda vivo tras el
build** — el pipeline no se autodestruye lo que acaba de desplegar, sería
absurdo (un "deploy" que desaparece solo no sirve para nada). Relanzar
`02_build.sh` simplemente recrea el contenedor con la imagen nueva
(mismo nombre de proyecto Compose). Pararlo es un paso manual explícito:
`./04_stop_deploy.sh` — **último paso del ejercicio**, no opcional: si se
deja corriendo, sigue conectado a la red compartida del laboratorio
(`jenkins_docker_pipeline_default`) y `100_destroy.sh` no podrá borrarla
(avisa `Resource is still in use`). `100_destroy.sh` también lo para por
si acaso, pero lo correcto es no dejarlo para el final.

Resultado esperado: `SUCCESS`.

## Dónde ver la imagen publicada

```shell
curl -u admin:admin123 http://localhost:8084/v2/spring-demo/tags/list
```

Verificado: `HTTP 200`, `{"name":"spring-demo","tags":["1","latest"]}`.

## Dónde ver el despliegue vivo

El contenedor (`demo-deploy-app-1`) solo está en la red interna de Compose
del laboratorio (`jenkins_docker_pipeline_default`, sin puertos publicados
al host), así que se comprueba desde dentro, por ejemplo desde el propio
controller:

```shell
docker exec jenkins_docker_pipeline curl -s http://app:8080/actuator/health
```

Verificado: `{"status":"UP",...}`.

## Cómo destruir el despliegue manualmente

```shell
./04_stop_deploy.sh
```

Qué hace exactamente:

```shell
docker rm -f $(docker ps -aq --filter "label=com.docker.compose.project=demo-deploy")
```

Localiza el/los contenedor(es) por el label que `docker compose` les pone
automáticamente (`com.docker.compose.project=demo-deploy`) y los elimina
con `docker rm -f`. No usa `docker compose -p demo-deploy down` porque
eso exigiría tener a mano el `compose.yaml` del despliegue — y ese fichero
solo existe dentro del workspace del job en Jenkins, no en el host; ir a
por el contenedor directamente por label evita esa dependencia.

Verificado:

```shell
docker ps --filter "label=com.docker.compose.project=demo-deploy"
# antes: demo-deploy-app-1   Up 11 minutes
./04_stop_deploy.sh
# f6f3aeb2ab35
# Despliegue 'demo-deploy' parado y eliminado.
docker ps -a --filter "label=com.docker.compose.project=demo-deploy"
# (vacío, ya no existe ni parado)
```

El script es idempotente: si no hay nada desplegado, lo detecta y sale sin
error (`No hay ningun contenedor del proyecto 'demo-deploy' en marcha.`) —
se puede ejecutar de más sin miedo a que falle.

## Cómo destruir el despliegue desde el propio pipeline (`05_approve_destroy.sh`)

La última stage del Jenkinsfile ("Destruir despliegue (manual)") se para
en un `input` con un `booleanParam DESTRUIR` a `false` por defecto.
`02_build.sh` (vía `build_job_input.sh` genérico) aprueba cualquier
`input` pendiente con sus valores por defecto, así que nunca destruye el
despliegue por esa vía — es la manera segura de verificar el ejemplo sin
intervención manual.

`05_approve_destroy.sh` es el script complementario, deliberadamente
distinto: lanza un build nuevo, espera a que llegue al `input` y lo
aprueba marcando `DESTRUIR=true`, para probar la destrucción **desde
dentro del propio pipeline** (a diferencia de `04_stop_deploy.sh`, que
para el despliegue con `docker` directo desde fuera de Jenkins):

```shell
./05_approve_destroy.sh
```

Resultado esperado: `SUCCESS`, con el despliegue (`demo-deploy`)
eliminado por la propia stage (`docker compose -p demo-deploy down
--remove-orphans`) en vez de por `04_stop_deploy.sh`.
