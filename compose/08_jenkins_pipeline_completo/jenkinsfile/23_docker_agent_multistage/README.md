# 23_docker_agent_multistage

Cada stage con `agent { docker {...} }` es un **contenedor nuevo** y un
workspace nuevo, aunque el pipeline entero use agentes Docker. Un stage con
agente Maven genera un fichero; sin `stash`/`unstash`, ese fichero no
existiría en el segundo stage (agente Node, contenedor distinto).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`; el segundo stage imprime el contenido del
fichero generado por el primero, recibido vía `unstash`.
