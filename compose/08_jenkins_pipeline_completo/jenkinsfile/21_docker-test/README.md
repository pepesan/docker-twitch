# 21_docker-test

Verifica que el controller puede hablar con el Docker del host
(docker-outside-of-docker) de dos formas: ejecutando `docker` directamente
en un stage, y dejando que Jenkins levante un contenedor efímero como
agente (`agent { docker {...} }`). Pipeline de verificación de la
infraestructura base del laboratorio.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Nota:** todos los stages usan `label 'built-in'` explícitamente — si
existe el agente SSH (`agent1`), Jenkins podría programar el stage ahí y
ese nodo no tiene Docker CLI instalado.

Resultado esperado: `SUCCESS`.
