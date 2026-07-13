# 05_post

`post {}` define acciones según el resultado final del build (`always`,
`success`, `failure`, `unstable`). Como este pipeline siempre termina bien,
solo se disparan `always` y `success`; los bloques `failure`/`unstable`
están para dejar claro cuándo se ejecutarían.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS` (en la consola se ven los mensajes de `always`
y `success`).
