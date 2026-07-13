# 24_docker_agent_dockerfile

En vez de tirar de una imagen pública de Docker Hub como agente, Jenkins
**construye su propia imagen** desde un Dockerfile
(`agent { dockerfile { filename '...' } }`) — control total del entorno de
build.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Nota:** como este laboratorio da de alta el job con un Jenkinsfile suelto
("Pipeline script", sin checkout de ningún repo), el primer stage escribe
el `Dockerfile.agent` en el workspace antes de que el segundo stage lo use
como agente — en un proyecto real, el Dockerfile viviría en el repo junto
al Jenkinsfile.

Resultado esperado: `SUCCESS`; se ve el build de la imagen a medida
(Alpine + curl/jq) y su uso.
