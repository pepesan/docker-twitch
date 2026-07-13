# 46_trivy_security_scans

Tres escaneos de seguridad con **Trivy** (Aqua Security), **en paralelo**
(igual que `07_parallel`), cada uno publicado como su propio resultado
JUnit con la plantilla que el propio Trivy incluye (`/contrib/junit.tpl`):

1. **Imagen generada aquí**: una `debian:10` construida en el propio
   pipeline (antigua a propósito, para garantizar CVEs reales).
2. **Imagen real ya construida en otro ejemplo**
   (`localhost:8084/spring-demo`, de `33_build_publish_deploy`).
3. **Dependencias npm** del proyecto `ejemplos-vue3-vite` (de `44`/`45`),
   con `trivy fs` en vez de `trivy image`.

La propia imagen `aquasec/trivy` es el **agente** de cada rama del
`parallel` (no un `docker run` anidado desde dentro de otra stage): trae
shell y `git` (es Alpine), así que puede hacer checkout y ejecutar Trivy
directamente, igual que `agent { docker {...} }` en el resto del
laboratorio (`22`, `32`, `40`...). Monta el socket del host para que
`trivy image` vea las imágenes ya construidas allí, sin necesitar el CLI
de Docker.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza (tarda: descarga la base de datos de Trivy)
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

**Requiere haber ejecutado `33_build_publish_deploy` antes**, al menos una
vez, para que exista la imagen `localhost:8084/spring-demo:latest` que
escanea la segunda rama.

**Resultado esperado: `UNSTABLE`, no `SUCCESS`** — con vulnerabilidades
reales encontradas en ambas imágenes (`debian:10` y `spring-demo`). Esto
**es correcto**, no un fallo del pipeline: el step `junit` marca
`UNSTABLE` cuando el informe tiene "tests" fallidos, y aquí cada CVE
encontrado se mapea a un `testcase` fallido. Como `./02_build.sh` solo
considera éxito un resultado `SUCCESS`, con este ejemplo **siempre saldrá
con código de salida distinto de cero** aunque el escaneo haya funcionado
perfectamente — es la única excepción de todo el laboratorio a
"`02_build.sh` en verde".

## Gotchas encontrados

- **No toda imagen antigua da resultados**: se probó primero con
  `alpine:3.14` (también EOL) y dio **0** vulnerabilidades. Alpine deja de
  rastrear CVEs de las ramas sin soporte por completo; Debian, en cambio,
  conserva el histórico aunque la versión esté descatalogada.
- **`trivy fs` necesita un lockfile** para resolver versiones exactas —
  un `package.json` suelto (con rangos tipo `^3.5.32`) no le vale, lo
  ignora entero (`Supported files for scanner(s) not found`). El repo
  `ejemplos-vue3-vite` no lleva `package-lock.json` comiteado (mismo
  gotcha que en `44`), así que la rama de dependencias instala Node/npm al
  vuelo con `apk` y genera el lockfile con
  `npm install --package-lock-only` antes de escanear.
- **La plantilla de JUnit se referencia con ruta absoluta**
  (`@/contrib/junit.tpl`, no `@contrib/junit.tpl`): el directorio de
  trabajo dentro del agente Docker es el workspace de Jenkins, no `/`,
  así que una ruta relativa no encuentra la plantilla.
- **El workspace se reutiliza entre builds** (mismo host, docker-outside-
  of-docker): sin borrar los `trivy-report*.xml` al principio de cada
  rama, un informe de un build anterior se sumaría al de este build
  (mismo gotcha que en `43_unit_vs_integration`).

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/46_trivy_security_scans/lastBuild/testReport/api/json"
```

**Desde la consola web**: menú lateral del build → enlace
**"Resultado de los tests"** — cada vulnerabilidad aparece como un test
fallido individual, con el CVE y la severidad en el nombre; al ser tres
ramas en paralelo, el resumen las agrupa por el nombre de cada `testsuite`
(uno por imagen/proyecto escaneado).
