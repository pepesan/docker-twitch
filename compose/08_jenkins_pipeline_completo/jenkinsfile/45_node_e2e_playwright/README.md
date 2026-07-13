# 45_node_e2e_playwright

Tests E2E reales con Playwright, mismo repo que `44_node_unit_tests`
(`github.com/pepesan/ejemplos-vue3-vite`, rama `master`). `playwright.config.ts`
ya trae `webServer` (arranca `npm run dev` solo, espera a que responda en
`http://localhost:5173/`, y lo para al terminar) — no hace falta levantar
la app a mano en el Jenkinsfile.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado (instala navegadores, tarda)
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`, 18 tests (6 specs × 3 navegadores:
Chromium, Firefox, WebKit).

## Sobre la imagen de los navegadores

En vez de fijar una imagen `mcr.microsoft.com/playwright` con un tag
concreto, se usa `node:22` + `npx playwright install --with-deps` en el
propio Jenkinsfile: así los navegadores instalados siempre coinciden con
la versión de `@playwright/test` que `npm install` resuelva del repo (que
no lleva `package-lock.json` comiteado, así que la versión exacta puede
variar). Coste: cada build reinstala los navegadores (más lento que una
imagen con todo precargado), pero elimina el riesgo de desajuste de
versión entre el binario del navegador y la librería de test.

**Posible mejora pendiente** (no implementada): cachear el resultado de
`npx playwright install --with-deps` entre builds (por ejemplo con un
volumen nombrado montado en `args`, como en `25_docker_agent_cache`), o
directamente usar una imagen `mcr.microsoft.com/playwright` con los
navegadores ya preinstalados si se fija la versión de `@playwright/test`
del repo (añadiendo un `package-lock.json`). Ahora mismo cada build
reinstala todo desde cero.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/45_node_e2e_playwright/lastBuild/testReport/api/json"
curl -u admin:admin "http://localhost:8082/job/45_node_e2e_playwright/lastBuild/artifact/playwright-report/html/index.html"
```

Verificado: ambas `HTTP 200`. El reporter HTML de Playwright genera un
único `index.html` autocontenido (JS/CSS/datos embebidos), no una carpeta
con muchos ficheros — por eso solo se archiva uno.

**Desde la consola web**, dos páginas distintas:

- **Página del build** (`.../lastBuild/`): menú lateral → **"Resultado de
  los tests"** (resumen JUnit de ese build); el `index.html` del informe
  HTML de Playwright está en la sección **"Artefactos Generados"**, en el
  cuerpo de la propia página (no en el menú lateral).
- **Página principal del job** (`.../45_node_e2e_playwright/`, sin
  `lastBuild`): sección **"Tendencia de los resultados de pruebas"**
  (histórico entre builds) y **"Last Successful Artifacts"** (enlace
  directo al `index.html` del último build correcto — este rótulo se
  queda en inglés, no está traducido).
