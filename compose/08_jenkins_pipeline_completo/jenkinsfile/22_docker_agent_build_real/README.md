# 22_docker_agent_build_real

Ejemplo real de `agent { docker {...} }` (a diferencia de `21_docker-test`,
que solo comprobaba `mvn --version`): clona el proyecto Spring Boot real
[spring-boot-30-demo-maven](https://gitlab.com/pepesan/spring-boot-30-demo-maven)
y hace un build Maven de verdad, archivando el `.jar` resultante.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado (descarga dependencias, tarda más la 1a vez)
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Nota:** usa `-DskipTests` porque el proyecto tiene una dependencia de
Testcontainers en sus tests, que necesitaría acceso al socket de Docker
dentro del propio agente (docker-in-docker anidado) — fuera del alcance de
este ejemplo. El testing real se cubre en la serie `40`.

Resultado esperado: `SUCCESS`; el `.jar` queda descargable desde la UI/API
del build.
