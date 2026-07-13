# 27_stash_unstash_agente

`stash`/`unstash` mueve ficheros entre stages aunque corran en workspaces o nodos distintos. Con `agent none` a nivel de pipeline, cada stage elige su propio nodo. En este caso, el primer stage se ejecuta en el controlador (`built-in`) y el segundo stage se ejecuta en el agente externo (`agent1`). Dado que corren en máquinas/contenedores y workspaces separados, la única forma de pasar archivos directamente entre ellos sin usar almacenamiento externo persistente es mediante `stash` y `unstash`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

**Requiere el agente SSH levantado** (`./04_launch_agent.sh` + `./05_check_agent.sh` desde la carpeta principal de `compose/`).

Resultado esperado: `SUCCESS`. El archivo `datos.txt` generado en el stage del controlador estará disponible en el stage del agente `agent1` después de ejecutar `unstash`.
