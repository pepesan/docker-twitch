# 04_parameters

`parameters {}` define los parámetros de entrada del build (string,
boolean, choice). Si se lanza sin especificar valores (como hace
`02_build.sh`), se usan los `defaultValue` de cada uno.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza con los valores por defecto y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`.
