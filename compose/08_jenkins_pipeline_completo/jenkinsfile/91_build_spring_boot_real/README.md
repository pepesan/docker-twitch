# 91_build_spring_boot_real

Ciclo completo del backend real, primer paso del pipeline "90+" (Spring
Boot + Astro): **tests reales** (mismo repo y técnica que
`40_junit_maven`/`43_unit_vs_integration`) y, por separado, **build de la
imagen** real con el Dockerfile propio del repo (mismo patrón que
`33_build_publish_deploy`). Publicar en Nexus es **opcional**
(`PUBLICAR_EN_NEXUS`, `false` por defecto) — eso ya se enseñó a fondo en
la serie 30 por separado; aquí el foco es dejar la imagen construida y
probada como base para `92_build_astro_real`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza (sin publicar en Nexus) y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`. Verificado: 4 tests pasados
(`failCount:0, passCount:4`), imagen `spring-boot-30-demo-maven:latest`
construida (549MB), stage "Publicar en Nexus" saltada (`when` no se
cumple con el valor por defecto).

## Publicar en Nexus (opcional)

Requiere Nexus levantado y configurado (`./08_launch_nexus.sh` +
`./09_setup_nexus.sh` desde la carpeta principal de `compose/`, ver
`30_nexus`). Lanzar con `PUBLICAR_EN_NEXUS=true`:

```shell
curl -u admin:admin -X POST \
  -H "$(curl -su admin:admin http://localhost:8082/crumbIssuer/api/json | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['crumbRequestField']+': '+d['crumb'])")" \
  --data-urlencode "PUBLICAR_EN_NEXUS=true" \
  http://localhost:8082/job/91_build_spring_boot_real/buildWithParameters
```

Verificado: `SUCCESS`, imagen publicada en
`localhost:8084/spring-boot-30-demo-maven:latest` (tags `latest` y
`BUILD_NUMBER`), mismo patrón de credencial (`nexus-creds`) que
`31_docker_push_nexus`.

**Gotcha habitual**: la primera vez hay que lanzar el job sin parámetros
(`02_build.sh`) — Jenkins no lo reconoce como parametrizado hasta que el
pipeline se ejecuta una vez y registra el bloque `parameters {}` (mismo
gotcha que `41_test_trend`/`43_unit_vs_integration`).

## Por qué dos checkouts (uno por stage)

Cada `agent { docker {...} }` es un **contenedor y workspace nuevos**
(ver `23_docker_agent_multistage`) — los ficheros de la stage de tests
(agente Maven) no existen en la de build (agente `built-in`) sin
`stash`/`unstash`. Aquí es más simple y barato repetir el `git url: ...`
en cada stage que mover ficheros entre agentes distintos.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/91_build_spring_boot_real/lastBuild/testReport/api/json"
docker images spring-boot-30-demo-maven
```

**Desde la consola web**: menú lateral del build → enlace
**"Resultado de los tests"**.
