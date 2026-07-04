# 41_test_trend

Genera un resultado de test (JUnit XML) que falla o no según el parámetro
`FORZAR_FALLO`, para ver cómo Jenkins construye el **histórico de
tendencia de tests** (Test Result Trend) entre varios builds: unos verdes,
otros con el test marcado como fallido (build `UNSTABLE`, no `FAILURE` —
`junit` solo degrada el resultado, no lo hace fallar del todo).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # 1er build: usa el valor por defecto (FORZAR_FALLO=false)
./03_delete.sh   # lo borra
```

**Nota:** la primera vez hay que lanzarlo con `02_build.sh` (sin
parámetros) — Jenkins no reconoce el job como parametrizado hasta que el
pipeline se ejecuta una vez y registra el `parameters {}`. A partir de ahí,
se puede lanzar con distintos valores vía
`.../buildWithParameters?FORZAR_FALLO=true`.

Resultado verificado: alternando `true`/`false` en sucesivos builds se
obtiene `SUCCESS`/`UNSTABLE`/`SUCCESS`/`UNSTABLE`/`SUCCESS`, visible en el
gráfico de tendencia del job.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/41_test_trend/lastBuild/testReport/api/json"
```

Verificado: `HTTP 200`. El gráfico de tendencia (histórico entre builds,
no solo el último) está en
`http://localhost:8082/job/41_test_trend/` (bajo "Test Result Trend"),
no en la API — la API solo expone el resultado de un build concreto.

**Desde la consola web**: el gráfico "Test Result Trend" aparece
directamente en la página principal del job (`41_test_trend` → página de
inicio, debajo del histórico de builds) — no hace falta entrar en ningún
build concreto. Para el resultado de un build suelto, menú lateral del
build → enlace **"Resultado de los tests"** (igual que en `40_junit_maven`).
