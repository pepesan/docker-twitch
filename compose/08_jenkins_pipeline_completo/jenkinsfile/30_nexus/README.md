# 30_nexus

**Requiere Nexus levantado y configurado** (`./08_launch_nexus.sh` +
`./09_setup_nexus.sh` desde la carpeta principal de `compose/`).

Verifica que el controller puede alcanzar Nexus por la red interna de
Docker Compose (nombre de servicio `nexus`, puerto interno `8081`, no el
`8083` publicado al host) — paso previo a publicar de verdad artefactos
(`31_docker_push_nexus`, `32_maven_deploy_nexus`).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```



Resultado esperado: `SUCCESS`.

**No genera artefactos** — solo comprueba conectividad, no hay nada que
descargar ni URL de Jenkins que documentar más allá de la consola del
build. Ver `31_docker_push_nexus`/`32_maven_deploy_nexus` para los
ejemplos que sí publican algo.
