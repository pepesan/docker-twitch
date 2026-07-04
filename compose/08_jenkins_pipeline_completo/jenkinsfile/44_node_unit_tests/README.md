# 44_node_unit_tests

Tests unitarios reales de un proyecto frontend Vue 3 + Vite con Vitest
(`github.com/pepesan/ejemplos-vue3-vite`, rama `master`). `vitest.config.ts`
ya genera JUnit XML en `coverage/junit.xml` — se publica con el mismo step
`junit` que `40_junit_maven`, sin tocar el repo.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`, 88 ficheros de test / 234 tests (3 no
contabilizados: 2 `skip` + 1 `todo`).

## Gotchas encontrados

- **El repo no lleva `package-lock.json` comiteado** — `npm ci` exige uno
  existente y falla con `EUSAGE`; hace falta `npm install` en su lugar.
- **Un test usa `.only` a propósito**, como ejemplo pedagógico de esa
  funcionalidad de Vitest (aislar un test). Vitest bloquea `.only` en modo
  CI por defecto (para detectar un `.only` olvidado por error) — aquí es
  intencional, así que el Jenkinsfile lo permite explícitamente con
  `npm run test:run -- --allowOnly`.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/44_node_unit_tests/lastBuild/testReport/api/json"
```

Verificado: `HTTP 200`, `{"failCount":0,"skipCount":3}`.

**Desde la consola web**: menú lateral del build → enlace
**"Resultado de los tests"**.
