# 25_docker_agent_cache

`args` monta un volumen nombrado (`jenkins_maven_cache_demo`) dentro del
contenedor del agente, para cachear el repositorio local de Maven entre
builds en vez de descargar las dependencias de cero cada vez.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # 1er build: cache vacía
./02_build.sh    # 2o build: cache ya poblada — compara el tiempo en consola
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado verificado: 9s en frío (1er build) vs. 1s con caché (2o build).
