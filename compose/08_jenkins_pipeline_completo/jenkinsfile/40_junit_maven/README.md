# 40_junit_maven

Ejecuta los tests reales (JUnit 5) de `spring-boot-30-demo-maven` con
Maven, y publica los resultados en Jenkins con el step `junit` (lee los
XML que Surefire genera en `target/surefire-reports/`). Sus tests son
slice tests (`@WebMvcTest`) y de contexto (`@SpringBootTest`): no necesitan
Docker dentro del propio agente.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

**Requiere el plugin `junit`** (ya incluido en `config/plugins.txt`).

Resultado esperado: `SUCCESS`, 4 tests ejecutados sin fallos.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/40_junit_maven/lastBuild/testReport/api/json"
```

Verificado: `HTTP 200`, `{"failCount":0,"passCount":4}`. Resumen navegable
en `http://localhost:8082/job/40_junit_maven/<build>/testReport/`.

**Desde la consola web**: entra en el build (`40_junit_maven` → número de
build) → menú lateral izquierdo → enlace **"Resultado de los tests"**
(así aparece en español; en inglés es "Tests").
