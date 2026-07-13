# 01_hello-world

Pipeline mínimo posible: `agent any` + un solo stage + un único paso `sh`.
Es la base de la que parten todos los demás ejemplos de esta carpeta.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`.
