# 42_jacoco_coverage

Ejecuta los tests reales de `spring-boot-30-demo-maven` con el agente
`jacoco-maven-plugin` enganchado (`prepare-agent`), genera el informe XML de
cobertura (`jacoco:report`) y lo publica en Jenkins con el step
`recordCoverage` (plugin `coverage`). No se toca el `pom.xml` del proyecto:
el plugin se invoca directamente en la línea de comandos de `mvn`, igual
que se hizo con `-DaltDeploymentRepository` en `32_maven_deploy_nexus`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Requiere el plugin `coverage`** (ya incluido en `config/plugins.txt`).

Resultado esperado: `SUCCESS`.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/42_jacoco_coverage/lastBuild/testReport/api/json"
curl -u admin:admin "http://localhost:8082/job/42_jacoco_coverage/lastBuild/coverage/api/json"
```

Verificado: ambas `HTTP 200`. Resumen navegable en
`http://localhost:8082/job/42_jacoco_coverage/<build>/testReport/` (tests)
y `http://localhost:8082/job/42_jacoco_coverage/<build>/coverage/`
(cobertura, con el desglose línea a línea del código fuente pintado).

**Desde la consola web**: menú lateral del build → **"Resultado de los
tests"** (resultado de test) y **"Coverage Report"** (informe de
cobertura — este último no está traducido al español, ni en el propio
plugin ni en la documentación oficial de Jenkins).
