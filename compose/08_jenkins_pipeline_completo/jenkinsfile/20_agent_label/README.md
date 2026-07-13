# 20_agent_label

Dirige el pipeline al agente SSH registrado (`agent { label 'agent1' }`),
en vez de al controller — la forma más simple de repartir carga de trabajo
a un nodo concreto.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Requiere el agente SSH levantado** (`./04_launch_agent.sh` +
`./05_check_agent.sh` desde la carpeta principal de `compose/`).

Resultado esperado: `SUCCESS`; el workspace en la consola es
`/home/jenkins/agent/...` (confirma que corrió en el agente, no en el
controller).
