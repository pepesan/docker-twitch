# 12_stash_unstash

`stash`/`unstash` mueve ficheros entre stages aunque corran en workspaces
(o nodos) distintos. `agent none` a nivel de pipeline: cada stage elige su
propio nodo. Para demostrarlo de forma sencilla sin requerir agentes externos,
ambos stages se ejecutan en el controller (`built-in`). Dado que se declaran en
stages diferentes, Jenkins les asigna workspaces aislados distintos (ej. `workspace` y
`workspace@2`), por lo que el segundo stage no ve los ficheros del primero
hasta hacer `unstash`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**No requiere de ningún agente externo levantado** (se ejecuta por completo en el nodo `built-in` de Jenkins).

Resultado esperado: `SUCCESS`.

