# 02_multiples_stages

Varias stages secuenciales (Build → Test → Deploy): Jenkins las ejecuta en
el orden en que aparecen en el `Jenkinsfile`, cada una tras terminar la
anterior.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`.
