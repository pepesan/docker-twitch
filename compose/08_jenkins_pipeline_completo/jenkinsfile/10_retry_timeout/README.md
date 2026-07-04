# 10_retry_timeout

`retry(N)` repite un bloque hasta N veces si falla; `timeout()` aborta un
paso si tarda más del límite indicado. El ejemplo simula una operación que
falla las 2 primeras veces y triunfa a la tercera.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`; en la consola se ven dos mensajes "ERROR...
Retrying" antes del intento 3, que sí triunfa.
