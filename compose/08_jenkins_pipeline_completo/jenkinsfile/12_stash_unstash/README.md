# 12_stash_unstash

`stash`/`unstash` mueve ficheros entre stages aunque corran en workspaces
(o nodos) distintos. `agent none` a nivel de pipeline: cada stage elige su
propio nodo, para demostrarlo de verdad entre el controller (`built-in`) y
el agente SSH (`agent1`).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

**Requiere el agente SSH levantado** (`./04_launch_agent.sh` +
`./05_check_agent.sh` desde la carpeta principal de `compose/`).

Resultado esperado: `SUCCESS`.
