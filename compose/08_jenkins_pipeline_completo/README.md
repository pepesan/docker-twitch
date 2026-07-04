# Jenkins controller automatizado (Docker Pipeline)

Laboratorio de verificación para la unidad de Jenkins CI/CD: un único
contenedor Jenkins controller que arranca completamente configurado (sin
asistente inicial) y con acceso al Docker del host, para poder ejecutar
Jenkinsfiles que usan `sh 'docker ...'` directamente o agentes
`agent { docker { image ... } }`.

## Contenido

| Fichero/carpeta | Descripción |
|---|---|
| `Dockerfile` | Imagen basada en `jenkins/jenkins:lts-jdk21` + Docker CLI/Buildx/Compose + plugins (`config/plugins.txt`) + Configuration as Code (`config/casc.yaml`). |
| `config/plugins.txt` | Lista de plugins instalados automáticamente vía `jenkins-plugin-cli` durante el build (detalle de cada uno más abajo, en "Plugins instalados"). |
| `config/casc.yaml` | Configuración JCasC: desactiva el asistente inicial y crea el usuario admin. |
| `compose.yaml` | `jenkins_controller` (siempre) con el socket de Docker del host montado (docker-outside-of-docker, sin `privileged` ni dind), y `jenkins_agent`/`jenkins_agent_docker`/`nexus` (opcionales, ver más abajo). |
| `Dockerfile.agent` | Imagen de `jenkins_agent_docker` (el segundo agente): `jenkins/ssh-agent:jdk21` + Docker CLI + usuario `jenkins` en el grupo del socket del host. |
| `config/init.groovy.d/configure-agent.groovy` | Script de arranque de Jenkins (idempotente): da de alta las credenciales SSH y los nodos permanentes `agent1`/`agent2` si no existen. **Importante:** se ejecuta en cada arranque, pero el fichero solo se copia a `jenkins_home` la primera vez (la imagen no sobreescribe reference files ya copiados) — si lo editas, hace falta `100_destroy.sh` + `00_init.sh` para que el cambio surta efecto (ver cabecera del propio fichero). Además, al usar `def metodo(...) {}` con nombre dentro de un fichero con guion (`configure-agent.groovy`) Groovy genera un nombre de clase ilegal — usar una closure (`def x = { ... }`) en su lugar. |
| `scripts/create_job.sh <nombre-job>` | Genérico: da de alta (o actualiza si ya existe) en Jenkins, vía API REST, el job `<nombre-job>` a partir de `jenkinsfile/<nombre-job>/Jenkinsfile`. |
| `scripts/build_job.sh <nombre-job>` | Genérico: lanza un build del job `<nombre-job>` y espera a que termine, mostrando el resultado y las últimas líneas de consola. No sabe nada de `input` — si el Jenkinsfile tiene uno, se queda esperando para siempre. |
| `scripts/build_job_input.sh <nombre-job>` | Excepción deliberada al genérico: igual que `build_job.sh`, pero además detecta un `input` pendiente y lo aprueba solo (con los valores por defecto de sus parámetros, si tiene). Solo lo usan los `02_build.sh` de los ejemplos que de verdad tienen un `input` en el Jenkinsfile (`08_input`, `33_build_publish_deploy`) — el resto usa el genérico, para no acoplar esa lógica a ejemplos que no la necesitan. |
| `scripts/delete_job.sh <nombre-job>` | Genérico: borra el job `<nombre-job>` si existe. |
| `scripts/delete_all_jobs.sh` | Genérico: borra todos los jobs dados de alta en Jenkins. |
| `jenkinsfile/NN_ejemplo/` | Una carpeta por cada ejemplo de pipeline, numerada empezando en `01_` y en orden de complejidad creciente (cada ejemplo se apoya en lo enseñado en el anterior). Autocontenida: `Jenkinsfile`, ficheros de apoyo si hacen falta, y su propia secuencia `01_create.sh`/`02_build.sh`/`03_delete.sh`. El nombre de la carpeta es también el nombre del job en Jenkins. |
| `00_init.sh` | Crea y prepara el directorio de volúmenes (`jenkins_home`) antes de arrancar. Solo pide lo necesario para el controller. |
| `01_launch.sh` | Construye la imagen y levanta **solo el controller** (`docker compose up -d --build`, sin el perfil `agent`). |
| `02_ps.sh` | Muestra el estado de los contenedores del stack. |
| `03_logs.sh` | Muestra los logs del controller en vivo (para depuración). |
| `04_launch_agent.sh` | **Opcional.** Genera la clave SSH del agente si no existe y levanta también `jenkins_agent` (`docker compose --profile agent up -d --build`). |
| `05_check_agent.sh` | **Opcional.** Comprueba contra la API de Jenkins que el nodo `agent1` aparece online (no solo que el contenedor está arrancado). |
| `06_launch_agent_docker.sh` | **Opcional.** Genera la clave SSH del segundo agente si no existe y levanta `jenkins_agent_docker` (`docker compose --profile agent-docker up -d --build`). |
| `07_check_agent_docker.sh` | **Opcional.** Comprueba contra la API de Jenkins que el nodo `agent2` aparece online. |
| `08_launch_nexus.sh` | **Opcional.** Levanta Nexus OSS (`docker compose --profile nexus up -d`), registro Docker + repositorio Maven en un único servicio. |
| `09_setup_nexus.sh` | **Opcional.** Espera a que Nexus esté listo y lo configura por completo sin pasos manuales: cambia la contraseña inicial, acepta el EULA, activa el realm de tokens Docker, crea los repositorios `maven-hosted`/`docker-hosted`, y da de alta la credencial Jenkins `nexus-creds`. |
| `99_delete_all_jobs.sh` | Borra todos los jobs de Jenkins (reset "blando": limpia jobs pero deja el controller corriendo). |
| `100_destroy.sh` | Para y elimina los contenedores (`down`) y borra los directorios de volúmenes (reset "duro" completo). |

## Uso

```shell
./00_init.sh
./01_launch.sh
./02_ps.sh
./03_logs.sh
```

### Servidores y datos de conexión

| Servicio | URL | Usuario | Contraseña | Variable de entorno | Disponible tras |
|---|---|---|---|---|---|
| Jenkins (UI) | `http://localhost:8082` | `admin` | `admin` | `JENKINS_ADMIN_ID` / `JENKINS_ADMIN_PASSWORD` | `./01_launch.sh` |
| Nexus (UI) | `http://localhost:8083` | `admin` | `admin123` (tras `./09_setup_nexus.sh`; aleatoria hasta entonces) | `NEXUS_ADMIN_PASSWORD` | `./08_launch_nexus.sh` + `./09_setup_nexus.sh` |
| Nexus (repo Maven) | `http://localhost:8083/repository/maven-hosted/` | `admin` | igual que la UI | — | `./08_launch_nexus.sh` + `./09_setup_nexus.sh` |
| Nexus (registro Docker) | `localhost:8084` (`docker login localhost:8084`) | `admin` | igual que la UI | — | `./08_launch_nexus.sh` + `./09_setup_nexus.sh` |
| Agente SSH `agent1` | `jenkins_agent:22` (red interna, no expuesto al host) | `jenkins` | clave SSH (`config/ssh/id_ed25519`, generada al vuelo, nunca comiteada) | — | `./04_launch_agent.sh` + `./05_check_agent.sh` |
| Agente SSH `agent2` (con Docker) | `jenkins_agent_docker:22` (red interna, no expuesto al host) | `jenkins` | clave SSH (`config/ssh/id_ed25519_agent2`, generada al vuelo, nunca comiteada) | — | `./06_launch_agent_docker.sh` + `./07_check_agent_docker.sh` |

Nexus es **opcional** (perfil `nexus`, ver `08_launch_nexus.sh`/
`09_setup_nexus.sh` más abajo) — solo hace falta para los ejemplos de la
serie `30` y `91`/`92`.

## Plugins instalados

`config/plugins.txt`, para qué sirve cada uno y en qué ejemplo se nota:

| Plugin | Para qué sirve |
|---|---|
| `git` | Step `git url: ...` para hacer checkout de un repositorio — lo usa cualquier ejemplo que clona un proyecto real (`22`, `31`, `32`, `33`, `40`, `41`, `42`). |
| `workflow-aggregator` | El paquete "Pipeline" completo (Declarative + Scripted, stages, steps básicos, `parallel`, `input`, `stash`/`unstash`...). Es la base de **todos** los ejemplos, no solo de uno. |
| `docker-workflow` | `agent { docker {...} }` / `agent { dockerfile {...} }` y el DSL `docker.build()`/`docker.image()` desde el propio Jenkinsfile — serie `20-26`. |
| `configuration-as-code` | Aplica `config/casc.yaml` al arrancar (desactiva el asistente inicial, crea el usuario admin) — sin esto habría que configurar Jenkins a mano por la UI la primera vez. |
| `ssh-slaves` | `SSHLauncher`: cómo el controller lanza y mantiene conectados los agentes permanentes `agent1`/`agent2` por SSH (`config/init.groovy.d/configure-agent.groovy`). |
| `junit` | Step `junit` para publicar resultados de test (lee los XML de Surefire/JUnit) y construir el histórico de tendencia — `40_junit_maven`, `41_test_trend`, `42_jacoco_coverage`. |
| `coverage` | Step `recordCoverage`, informe de cobertura JaCoCo — `42_jacoco_coverage`. |
| `pipeline-graph-view` | Vista gráfica moderna de las stages (incluidos paralelos, con duración y logs por stage) integrada en la página clásica del job — sustituye la pieza de Blue Ocean que más se echaba en falta, ya que Blue Ocean está descontinuado y sin mantenimiento. Se nota especialmente en `07_parallel` y en cualquier pipeline con varias stages. |

## Agente Jenkins (opcional)

El agente permite repartir la carga de trabajo entre el controller y un
segundo nodo. Es completamente **opcional**: los scripts de arranque
normales (`00_init.sh`, `01_launch.sh`) solo levantan el controller, no
requieren nada relacionado con el agente.

Esto se consigue con los **profiles de Docker Compose**: `jenkins_agent`
lleva `profiles: ["agent"]` en `compose.yaml`, así que `docker compose up`
(sin más) lo ignora. Solo se levanta si se activa explícitamente ese
perfil con `--profile agent`, que es justo lo que hace `04_launch_agent.sh`.

```shell
./04_launch_agent.sh   # genera la clave SSH si hace falta, levanta jenkins_agent
./05_check_agent.sh    # espera y confirma que el nodo 'agent1' está online en Jenkins
```

Detalles de implementación:

- La clave SSH (`config/ssh/id_ed25519{,.pub}`, generada por
  `04_launch_agent.sh`, nunca comprometida a git) se pasa a `jenkins_agent`
  como clave pública autorizada (variable `JENKINS_AGENT_SSH_PUBKEY` de la
  imagen oficial `jenkins/ssh-agent`), y al controller como directorio
  montado de solo lectura (`config/ssh:/var/jenkins_home/ssh:ro`) — el
  controller necesita la clave privada para conectar por SSH al agente.
- El script de arranque `config/init.groovy.d/configure-agent.groovy` crea,
  de forma idempotente, la credencial SSH y el nodo permanente `agent1`
  (label `agent1`, 2 executors) en el propio Jenkins la primera vez que
  arranca — sin pasos manuales por la UI.
- Al montar el directorio completo (no un fichero suelto), el mismo
  `compose.yaml` funciona tanto si el agente nunca se levanta (el
  directorio simplemente está vacío) como si se genera la clave más tarde.

## Segundo agente, con Docker (opcional)

`agent1` (arriba) es un agente SSH "puro", sin Docker CLI — a propósito,
para no necesitarlo salvo que un ejemplo lo pida. `agent2` es un segundo
agente SSH independiente que **sí** tiene Docker CLI + el socket del host
montado, para ejemplos que necesiten ejecutar tareas Docker reales desde un
agente (no desde el controller).

```shell
./06_launch_agent_docker.sh   # genera su clave SSH si hace falta, levanta jenkins_agent_docker
./07_check_agent_docker.sh    # espera y confirma que el nodo 'agent2' está online en Jenkins
```

Detalles de implementación:

- `Dockerfile.agent` extiende `jenkins/ssh-agent:jdk21` instalando
  `docker-ce-cli` y añadiendo el usuario `jenkins` al grupo del GID del
  socket de Docker del host (`999` en esta máquina; comprobar con
  `stat -c '%g' /var/run/docker.sock` si difiere) — el agente SSH ejecuta
  los steps como usuario `jenkins`, no root, así que sin esto daría
  "permission denied" al hablar con el socket.
- **Importante:** no se añade `USER jenkins` al final del `Dockerfile.agent`
  — el `setup-sshd` de la imagen base necesita arrancar como root (crea el
  usuario SSH, ajusta permisos, y solo luego lanza `sshd`).
- Misma clave pública/privada por directorio montado que `agent1`
  (`config/ssh/id_ed25519_agent2{,.pub}`), gestionado igual por
  `configure-agent.groovy` (ver detalle de la closure en la tabla de
  arriba).

## Nexus OSS (opcional)

Registro Docker y repositorio Maven en un único servicio, para los
ejemplos de la serie `30` (publicación de artefactos).

```shell
./08_launch_nexus.sh   # levanta Nexus (perfil "nexus")
./09_setup_nexus.sh    # espera, configura y crea los repos + credencial Jenkins
```

Detalles de implementación:

- Puertos: `8083` (UI + API REST), `8084` (conector del repositorio Docker
  hosted). El puerto `8081` interno de Nexus no se publica al host.
- `nexus_data/` (bind mount, como `jenkins_home/`) persiste el estado;
  Nexus deja un `admin.password` aleatorio ahí la primera vez, que
  `09_setup_nexus.sh` usa una sola vez para fijar la contraseña definitiva
  (`admin`/`admin123` por defecto, `NEXUS_ADMIN_PASSWORD` para cambiarla).
- Nexus Community Edition exige aceptar un EULA por API antes de poder usar
  los repositorios — `09_setup_nexus.sh` lo hace automáticamente.
- El realm **DockerToken** debe activarse explícitamente para que
  `docker login` funcione contra el repositorio Docker hosted.
- **Redes:** `docker build`/`push`/`login` (vía `sh` en un stage con
  `agent { label 'built-in' }`) usan `localhost:8084` porque pasan por el
  socket al daemon del host (docker-outside-of-docker). Pero un `agent {
  docker {...} }` efímero, o un `curl` directo desde dentro del propio
  contenedor del controller, necesitan el nombre de servicio de Compose
  (`nexus:8081`/`nexus:8084`) y estar conectados a la red
  `jenkins_docker_pipeline_default` (`--network` en `args` si es un agente
  Docker efímero) — son dos formas de llegar al mismo Nexus, no
  intercambiables.

## Cómo dar de alta y lanzar un ejemplo

Cada carpeta bajo `jenkinsfile/NN_ejemplo/` es autocontenida y lleva su
propia secuencia de scripts, que **no necesitan editarse**: el nombre del
job se deriva automáticamente del nombre de la carpeta (`basename` del
directorio donde vive el script).

```shell
./jenkinsfile/01_hello-world/01_create.sh   # da de alta (o actualiza) el job
./jenkinsfile/01_hello-world/02_build.sh    # lo lanza y espera el resultado
./jenkinsfile/01_hello-world/03_delete.sh   # lo borra
```

Internamente estos tres scripts solo hacen `cd` a su propia carpeta y
delegan en la lógica genérica de `compose/scripts/` pasándole su propio
nombre de carpeta. Esto mantiene la raíz de `compose/` limpia (solo la
infraestructura común) por muchos ejemplos que se añadan.

## Cómo añadir un ejemplo de pipeline nuevo

1. Crea una carpeta nueva bajo `jenkinsfile/NN_nombre-ejemplo/` (siguiente
   número disponible en la hoja de ruta, ver más abajo) con el `Jenkinsfile`
   (y cualquier fichero de apoyo que necesite: Dockerfiles de la app,
   configuración, etc.).
2. Copia los tres scripts `01_create.sh`, `02_build.sh`, `03_delete.sh` de
   cualquier ejemplo ya existente (p.ej. `jenkinsfile/01_hello-world/`) —
   son idénticos entre ejemplos, no hace falta tocarlos. **Excepción:** si
   el Jenkinsfile nuevo tiene un `input`, el `02_build.sh` debe llamar a
   `../../scripts/build_job_input.sh` en vez de `build_job.sh` (ver tabla
   de arriba) — si no, el script se queda esperando para siempre.
3. Da de alta y lanza: `./jenkinsfile/NN_nombre-ejemplo/01_create.sh` seguido
   de `./jenkinsfile/NN_nombre-ejemplo/02_build.sh`.

Si editas el `Jenkinsfile` de un ejemplo ya existente, vuelve a ejecutar su
`01_create.sh` — detecta que el job ya existe y actualiza su configuración
en vez de fallar.

### Ejemplos disponibles

| Carpeta | Qué enseña |
|---|---|
| `jenkinsfile/01_hello-world/` | Pipeline mínimo: `agent any` + un solo stage + un `sh`. |
| `jenkinsfile/02_multiples_stages/` | Varias stages secuenciales (Build/Test/Deploy). |
| `jenkinsfile/03_environment/` | Bloque `environment {}` global y su override en un stage concreto. |
| `jenkinsfile/04_parameters/` | `parameters {}` (string/boolean/choice) leídos con `params.*`. |
| `jenkinsfile/05_post/` | `post { always/success/failure/unstable }` — solo se disparan `always`/`success` en un build correcto. |
| `jenkinsfile/06_when/` | `when { expression {...} }` para ejecutar (u omitir) un stage según un parámetro. |
| `jenkinsfile/07_parallel/` | Tres stages en paralelo (`parallel {}`) con salida intercalada. |
| `jenkinsfile/08_input/` | Aprobación manual con `input`; `scripts/build_job_input.sh` la aprueba solo vía API para poder verificarlo sin intervención. |
| `jenkinsfile/09_credentials/` | `withCredentials` con los 4 tipos de credencial (usuario/contraseña, texto secreto, clave SSH, fichero); `00_create_credentials.sh` las da de alta antes de lanzar el job. |
| `jenkinsfile/10_retry_timeout/` | `retry(3)` sobre una operación que falla las 2 primeras veces, y `timeout()` sobre un paso rápido. |
| `jenkinsfile/11_archive_artifacts/` | `archiveArtifacts` + `fingerprint`, artefacto descargable tras el build. |
| `jenkinsfile/12_stash_unstash/` | `stash`/`unstash` moviendo un fichero entre el controller y `agent1` (nodos distintos). |
| `jenkinsfile/20_agent_label/` | Pipeline dirigido a `agent { label 'agent1' }`, usando el agente SSH registrado. |
| `jenkinsfile/21_docker-test/` | Que el controller puede ejecutar `docker` directamente y levantar agentes Docker efímeros (Maven, Node) — pipeline de verificación de la infraestructura base. |
| `jenkinsfile/22_docker_agent_build_real/` | Checkout real de un proyecto Spring Boot + `agent { docker {...} }` ejecutando `mvn clean package` de verdad, con el `.jar` archivado. |
| `jenkinsfile/23_docker_agent_multistage/` | Distintos agentes Docker por stage (Maven → Node), pasando un fichero entre ellos con `stash`/`unstash`. |
| `jenkinsfile/24_docker_agent_dockerfile/` | `agent { dockerfile {...} }`: la imagen del agente se construye desde un `Dockerfile` propio, no de una imagen pública. |
| `jenkinsfile/25_docker_agent_cache/` | `args` monta un volumen nombrado para cachear dependencias Maven entre builds (9s en frío vs. 1s con caché). |
| `jenkinsfile/26_agent_docker_task/` | `agent { label 'agent2' }`: tarea Docker real ejecutada desde el segundo agente SSH (que sí tiene Docker CLI), a diferencia de `agent1`. |
| `jenkinsfile/30_nexus/` | Comprueba que el controller alcanza Nexus por la red interna de Compose — paso previo a publicar de verdad. |
| `jenkinsfile/31_docker_push_nexus/` | `docker build` + `push` (tags `BUILD_NUMBER` y `latest`) al repositorio Docker de Nexus, con la credencial `nexus-creds`. |
| `jenkinsfile/32_maven_deploy_nexus/` | `mvn deploy` de un proyecto Maven real al repositorio Maven de Nexus, sin tocar su `pom.xml` (`-DaltDeploymentRepository`). |
| `jenkinsfile/33_build_publish_deploy/` | Cierre de ciclo: build de la imagen real (con su propio Dockerfile), publicación en Nexus, despliegue con `docker compose up` y verificación del healthcheck; despliegue destruible manualmente (`04_stop_deploy.sh` o una stage `input`). |
| `jenkinsfile/40_junit_maven/` | `mvn test` real sobre `spring-boot-30-demo-maven`, publicado con el step `junit`. |
| `jenkinsfile/41_test_trend/` | Histórico de tendencia de tests (Test Result Trend) entre builds, alternando `SUCCESS`/`UNSTABLE` según un parámetro. |
| `jenkinsfile/42_jacoco_coverage/` | Cobertura de código JaCoCo publicada con `recordCoverage` (plugin `coverage`). |
| `jenkinsfile/43_unit_vs_integration/` | Tests unitarios (rápidos) e integración (lentos) en stages distintas, fail-fast si los unitarios fallan. |
| `jenkinsfile/44_node_unit_tests/` | Tests unitarios reales (Vitest) de un proyecto Vue 3 + Vite, publicados con `junit`. |
| `jenkinsfile/45_node_e2e_playwright/` | Tests E2E reales con Playwright (mismo proyecto Vue 3), 3 navegadores. |
| `jenkinsfile/46_trivy_security_scans/` | Tres escaneos de seguridad con Trivy en paralelo: imagen generada aquí, imagen real de `33`, dependencias npm del proyecto Vite. |
| `jenkinsfile/50_deploy_docker_run/` | `docker run -d` idempotente: sustituye el contenedor anterior si ya existe, no falla ni acumula. |
| `jenkinsfile/51_deploy_compose_up/` | App multicontenedor (`app` + `db`) con `docker compose up -d`; `app` espera a que `db` esté *healthy*. |
| `jenkinsfile/52_deploy_multientorno/` | Despliegue a `staging`/`producción` por parámetro `choice`, con proyecto Compose y `.env` distintos por entorno (coexisten a la vez). |
| `jenkinsfile/53_deploy_rollback/` | Taggea la versión anterior antes de desplegar la nueva; rollback manual (`input`) si la nueva versión no arranca. |
| `jenkinsfile/90_gitlab_token_credential/` | Credencial de acceso a un repo privado de GitLab (token vía `.env`, nunca comiteado); verifica el checkout real del frontend Astro. |
| `jenkinsfile/91_build_spring_boot_real/` | Ciclo completo del backend real: tests (agente Maven) + build de la imagen con su propio Dockerfile; publicación en Nexus opcional (`PUBLICAR_EN_NEXUS`). |
| `jenkinsfile/92_build_astro_real/` | Ciclo completo del frontend Astro real (repo privado): build con su propio Dockerfile, escaneo Trivy, publicación en Nexus y despliegue de prueba. |

### Hoja de ruta (pendiente de construir)

Numeración por bandas temáticas (ver detalle completo en `BACKLOG.md`):

| Banda | Tema |
|---|---|
| `20-26` | Agentes (SSH + Docker) — **completa** ✅ |
| `30-33` | Artefactos con Nexus OSS (registro Docker + repositorio Maven) — **completa** ✅ |
| `40-46` | Testing (JUnit/Maven, cobertura JaCoCo, unit vs integración, Node unit + E2E) + escaneo de seguridad (Trivy) — completa ✅ |
| `50-53` | Despliegues con Docker y Docker Compose — completa ✅ |
| `60-89` | *(reservado)* |
| `90+` | Pipeline real Spring Boot (`gitlab.com/pepesan/spring-boot-30-demo-maven`) + Astro (`gitlab.com/cursosdedesarrollo/blog`, repo privado) — completa (`90`-`92`) ✅ |

`90+` es una banda fija: no se renumera aunque cambien las demás.

## Limpieza

```shell
./99_delete_all_jobs.sh   # borra todos los jobs, deja el controller corriendo
./100_destroy.sh          # para los contenedores y borra jenkins_home entero
```

## Lecciones técnicas (gotchas encontrados construyendo este laboratorio)

- **`init.groovy.d/*.groovy` solo se copia una vez.** La imagen oficial de
  Jenkins copia los ficheros de `/usr/share/jenkins/ref/` a `$JENKINS_HOME`
  solo si el destino no existe todavía. Reconstruir la imagen (incluso
  `--no-cache`) no actualiza un script ya copiado — hace falta
  `100_destroy.sh` + `00_init.sh` para un `jenkins_home` limpio, o
  `docker cp` del fichero corregido + `docker restart` como atajo rápido
  en desarrollo.
- **Groovy + nombre de fichero con guion.** Un `def metodo(...) {}` con
  nombre dentro de un script cuyo fichero tiene guion
  (`configure-agent.groovy`) genera un nombre de clase interna ilegal
  (`ClassFormatError`). Usar una **closure** (`def x = { params -> ... }`)
  en su lugar.
- **`agent { docker {...} }` no ve la red de Compose por defecto.** Un
  contenedor efímero creado así se conecta a la red bridge por defecto, no
  a `jenkins_docker_pipeline_default` — para que resuelva `nexus` (o
  cualquier otro servicio) hace falta `--network
  jenkins_docker_pipeline_default` en `args`.
- **`docker build`/`push`/`login` vs. `curl` no son intercambiables para
  llegar a Nexus.** Los primeros pasan por el socket al daemon del host
  (usan `localhost:8084`); un `curl` que corre dentro del propio
  contenedor del controller necesita el nombre de servicio de Compose
  (`nexus:8084`).
- **`Content-Type` sin `charset=UTF-8` corrompe tildes/rayas al
  *actualizar* un job.** `POST /job/$NAME/config.xml` sin
  `;charset=UTF-8` explícito hacía que Jenkins decodificara el body como
  ISO-8859-1 → HTTP 500 con `Unicode: 0x80` en el mensaje. La ruta de
  *creación* (`createItem`) no tenía el problema, solo la de actualización.
- **`USER jenkins` al final del `Dockerfile.agent` rompe `jenkins/ssh-agent`.**
  Su entrypoint `setup-sshd` necesita arrancar como root (crea el usuario
  SSH, ajusta permisos, y solo luego lanza `sshd`).
- **El agente SSH ejecuta los steps como usuario `jenkins`, no root** (a
  diferencia del controller, que es root vía `user: root` en
  `compose.yaml`) — para que pueda usar `/var/run/docker.sock` hace falta
  añadirlo a un grupo con el mismo GID que el grupo `docker` del host
  (`usermod -aG <GID> jenkins`; comprobar con
  `stat -c '%g' /var/run/docker.sock`, puede no llamarse "docker" dentro
  de la imagen).
- **Nexus Community Edition exige aceptar un EULA por API** antes de poder
  usar los repositorios, y el realm **DockerToken** debe activarse
  explícitamente para que `docker login` funcione.

## Estado

Verificado end-to-end: el controller (opcionalmente con uno o dos agentes
SSH y/o Nexus) arranca sin pasos manuales, y los ejemplos de `jenkinsfile/`
están dados de alta y construidos con resultado `SUCCESS` cada uno vía su
propia secuencia `01_create.sh`/`02_build.sh`. Las bandas `01-12`
(sintaxis Declarative Pipeline), `20-26` (agentes SSH y Docker), `30-33`
(artefactos con Nexus), `40-46` (testing + seguridad), `50-53`
(despliegues) y `90-92` (pipeline real Spring Boot + Astro) están
completas.

Pendiente: banda reservada `60-89` (sin uso todavía) y el resto de tareas
de `BACKLOG.md` fuera del laboratorio Jenkins en sí (revisión de
`_07.yaml`, `ejercicios/`, revisión de seguridad sistemática).
