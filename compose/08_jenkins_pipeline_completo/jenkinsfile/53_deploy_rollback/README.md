# 53_deploy_rollback

Estrategia de actualización con rollback: antes de desplegar la imagen
nueva, se **taggea la que estaba corriendo** (si había alguna) como
`demo-rollback-app:previous`. Tras desplegar, se comprueba que el
contenedor sigue vivo unos segundos después — si no (simulado con
`FORZAR_FALLO_SALUD`), se ofrece un **rollback manual** con `input`
(mismo patrón que `33_build_publish_deploy`: `booleanParam ROLLBACK` a
`false` por defecto, solo vuelve atrás si un humano marca la casilla).
Conecta con `08_input` y el tagging semántico de la serie 30.

## Cómo probarlo

```shell
./01_create.sh      # da de alta (o actualiza) el job en Jenkins
./02_build.sh        # lo lanza con el valor por defecto (despliegue sano)
./04_stop_deploy.sh  # último paso del ejercicio: para el despliegue de prueba
./03_delete.sh       # borra el job de Jenkins
```

Resultado esperado: `SUCCESS`, contenedor corriendo, stage "Rollback (si
hace falta)" saltada (`when` no se cumple).

El despliegue **queda vivo tras el build** — mismo criterio que el resto
de la serie 50. `./04_stop_deploy.sh` es el **último paso del ejercicio**,
no opcional: no dejarlo para "cuando ya no haga falta", para no acumular
contenedores de pruebas anteriores. `100_destroy.sh` también lo para por
si acaso, pero lo correcto es no dejarlo para el final.

## Probar el rollback de verdad

Con `FORZAR_FALLO_SALUD=true` la nueva versión se cae nada más arrancar
(`exit 1`), la stage "Verificar salud" lo detecta, y la de rollback pide
confirmación. Como `02_build.sh` (vía `build_job_input.sh`) aprueba
cualquier `input` pendiente con sus valores por defecto (`ROLLBACK=false`),
para probar el rollback *de verdad* hay que aprobarlo a mano marcando la
casilla — o vía API:

```shell
# lanzar con FORZAR_FALLO_SALUD=true, esperar a que llegue al input,
# y aprobarlo con ROLLBACK=true (ver 33_build_publish_deploy/05_approve_destroy.sh
# para el mismo patron con un script dedicado)
```

Verificado: tras aprobar con `ROLLBACK=true`, el contenedor vuelve a
correr con la imagen `demo-rollback-app:previous` (`Up`, `result: SUCCESS`).
Sin marcar la casilla, el contenedor se queda caído (`exited`) y el
pipeline igualmente reporta `SUCCESS` — el rollback es una decisión, no
una corrección automática.

## Dónde ver el resultado

```shell
docker inspect -f '{{.State.Running}}' demo-rollback-app
docker inspect -f '{{.Config.Image}}' demo-rollback-app
```

**Desde la consola web**: igual que `08_input`/`33_build_publish_deploy` —
Console Output del build muestra el mensaje del `input` con los botones
embebidos al final del log, o el enlace **"Paused for Input"** en el menú
lateral lleva a la misma pregunta en una página dedicada.
