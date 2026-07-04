# 06_when

`when {}` decide en tiempo de ejecución si un stage se ejecuta o se omite,
según una condición (aquí, el valor del parámetro `DESPLEGAR`).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza (DESPLEGAR=true por defecto) y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`; en la consola se ve el stage "Deploy" activo
y "Deploy omitido a proposito" marcado como `skipped due to when
conditional`.
