# 03_environment

Bloque `environment {}` a nivel de pipeline (global) y a nivel de stage
(solo aplica ahí, y solo mientras dura ese stage; fuera de él, vuelve a
verse el valor global).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`.
