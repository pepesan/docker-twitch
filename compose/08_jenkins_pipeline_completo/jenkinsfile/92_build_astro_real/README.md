# 92_build_astro_real

Ciclo completo del frontend Astro real, segundo (y último) paso del
pipeline "90+" (Spring Boot + Astro): checkout del repo **privado**
`gitlab.com/cursosdedesarrollo/blog` (credencial `gitlab-blog-token` de
`90_gitlab_token_credential`) + `docker build` directo con **el Dockerfile
propio del repo** — mismo patrón que `33_build_publish_deploy` y
`91_build_spring_boot_real`, no hace falta reimplementar los pasos de
build de Astro (`pnpm install`/`pnpm build`) a mano: ya están en su
Dockerfile multi-stage (`node:22-alpine` + `pnpm build` → `nginx-unprivileged`
sirviendo `dist/`). Si la verificación pasa, se publica en Nexus (mismo
patrón que `31_docker_push_nexus`) y se hace un despliegue de prueba.

## Sobre las pruebas del propio proyecto

El repo **no define ningún test propio**: `package.json` no tiene script
`test` (solo `dev`/`build`/`preview`/`lint`/`release`), y su
`.gitlab-ci.yml` es la plantilla genérica de GitLab **sin personalizar**
— dice literalmente en su cabecera *"Instead of real tests or scripts, it
uses echo commands to simulate the pipeline execution"*. No hay
dependencias/secretos/licencia/unitarios/e2e que reutilizar. Lo único que
se añade sin depender del proyecto es un **escaneo de la imagen con
Trivy** (mismo patrón que `46_trivy_security_scans`).

## Requisitos

- `90_gitlab_token_credential` ejecutado antes (credencial `gitlab-blog-token`
  dada de alta).
- Nexus levantado y configurado para la stage "Publicar en Nexus" (ver
  `30_nexus`).

## Cómo probarlo

```shell
./01_create.sh      # da de alta (o actualiza) el job en Jenkins
./02_build.sh        # lo lanza y espera el resultado (build de Astro, tarda)
./05_stop_deploy.sh  # último paso del ejercicio: para el despliegue de prueba
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # borra el job de Jenkins
```

Resultado esperado: `SUCCESS`. Verificado: 528 páginas construidas por
Astro, imagen publicada en Nexus, despliegue de prueba respondiendo
`HTTP 200` en `http://localhost:8098/`, escaneo de Trivy sin
vulnerabilidades (`0 tests, 0 failures`).

**Historia real**: el primer escaneo encontró 13 CVEs reales (todas del
mismo paquete, `libexpat-2.8.1-r0`, heredado del `alpine` base de
`nginx-unprivileged`) — `apk update && apk upgrade` lo sube a `2.8.2-r0`,
ya parcheado. Se probó primero como una stage de "hardening" en este
mismo Jenkinsfile (reconstruir la imagen con el upgrade aplicado encima y
reescanear), pero el arreglo real y permanente es en el propio
`Dockerfile` del repo, no repetirlo en cada build aquí — el usuario tiene
permisos de escritura en `cursosdedesarrollo/blog` y lo aplicó
directamente en la rama `master` (`USER root` + `apk update && apk upgrade
--no-cache` + `USER nginx` antes del `COPY` final). Confirmado: con el
Dockerfile ya corregido en origen, el escaneo da 0 vulnerabilidades sin
necesitar ninguna stage adicional en este pipeline.

El despliegue **queda vivo tras el build** — mismo criterio que toda la
serie 50. Pararlo es un paso manual explícito: `./05_stop_deploy.sh` —
**último paso del ejercicio**, no opcional: no dejarlo para "cuando ya no
haga falta", para no acumular contenedores de pruebas anteriores.
`100_destroy.sh` también lo para por si acaso, pero lo correcto es no
dejarlo para el final.

## Gotcha: docker-outside-of-docker y "localhost"

La stage de verificación levanta un contenedor efímero de la imagen recién
construida y comprueba que responde. La primera versión publicaba el
puerto al host (`-p 8095:8080`) y hacía `curl http://localhost:8095/` —
daba **`HTTP 000`** siempre, porque el `sh` corre *dentro* del contenedor
del controller (docker-outside-of-docker): su `localhost` no es el mismo
`localhost` que el host real donde de verdad se publicó el puerto (mismo
gotcha que `33_build_publish_deploy`). Arreglado conectando el contenedor
a la red de Compose (`--network jenkins_docker_pipeline_default`, sin
`-p`) y llamándolo **por nombre** (`http://blog-astro-verify:8080/`) en
vez de por `localhost` + puerto publicado.

## Dónde ver el resultado

```shell
curl -u admin:admin "http://localhost:8082/job/92_build_astro_real/lastBuild/testReport/api/json"
curl http://localhost:8098/   # el despliegue de prueba, mientras siga vivo
```

Verificado: `0` vulnerabilidades (Trivy, tras el fix en el repo), `HTTP 200`
(despliegue).

**Desde la consola web**: menú lateral del build → **"Resultado de los
tests"** (hallazgos de Trivy). `Console Output` muestra el log completo de
`astro build` (528 páginas) en la stage "Build de la imagen".
