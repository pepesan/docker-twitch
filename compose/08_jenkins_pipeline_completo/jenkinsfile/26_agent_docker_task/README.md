# 26_agent_docker_task

Dirige el pipeline al agente SSH **`agent2`** (con Docker CLI + socket del
host, ver `06_launch_agent_docker.sh`) y ejecuta una tarea Docker real
desde el propio agente — a diferencia de `agent1` (`20_agent_label`), que
no tiene Docker CLI instalado a propósito.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Requiere el segundo agente levantado**
(`./06_launch_agent_docker.sh` + `./07_check_agent_docker.sh` desde la
carpeta principal de `compose/`).

Resultado esperado: `SUCCESS`; se ve `docker version` y un
`docker run --rm alpine:3.20 echo ...` ejecutados en `agent2`.
