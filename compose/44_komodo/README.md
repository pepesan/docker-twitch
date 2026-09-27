# Komodo — alternativa a Portainer con soporte Docker Swarm

[Komodo](https://komo.do) es un panel de gestión Docker self-hosted:
servidor central (**Core**) + un agente (**Periphery**) por cada máquina
Docker que quieras administrar, sin límite de servidores. A diferencia de
otras alternativas a Portainer (Coolify, Dockge, Dockhand), Komodo sí
gestiona **Docker Swarm** de forma nativa (clusters, nodos, services,
stacks, configs, secrets) desde su v2.0.0.

## Componentes que se arrancan

Este `compose.yaml` levanta 3 contenedores, cada uno con un papel distinto:

- **`mongo`** (`mongo:8.2`): la base de datos. Aquí se guarda todo lo que
  Komodo conoce — servidores registrados, stacks, builds, usuarios, alertas,
  historial. Sin este contenedor no arranca `core` (no tiene dónde persistir
  nada). No expone puerto al host (solo accesible en la red interna del compose).

- **`core`**: el "cerebro" y la parte con la que interactúas. Sirve la Web UI
  y la API (puerto **9120**, el único publicado al host), gestiona usuarios/login,
  guarda/lee todo en `mongo`, y habla por WebSocket con cada `periphery` para
  mandarle órdenes (desplegar un stack, arrancar/parar un contenedor, etc.).
  Es el único punto que ves y al que te conectas desde el navegador.

- **`periphery`**: el **agente** que se instala en cada servidor Docker que
  quieras que Komodo gestione. No tiene UI propia: se conecta a `core` por
  WebSocket (`ws://core:9120`), monta el socket de Docker del host
  (`/var/run/docker.sock`) y ejecuta ahí las órdenes que `core` le manda. En
  este despliegue solo hay un `periphery`, gestionando el propio Docker de la
  máquina donde lo lances (aparece en Komodo como servidor "Local") — en un
  uso real instalarías un `periphery` por cada servidor adicional que
  quieras añadir, la misma idea que los *edge agents* de Portainer, pero sin
  límite de servidores.

## Por qué `mongo:8.2` y no `mongo` (latest)

El tag `mongo`/`mongo:latest` puede resolver a una versión de MongoDB
incompatible con kernels recientes (bug conocido `SERVER-121912`, kernels
6.19+) — el contenedor no llega a arrancar en esos hosts. Fijar la imagen a
**`mongo:8.2`** evita el problema sin necesidad de recurrir a alternativas
como FerretDB+Postgres. Si tu host da el mismo error, revisa qué versión
resuelve tu tag y fija una anterior probada.

## Uso

```bash
cd compose/44_komodo
./00_init.sh                   # (solo la primera vez) crea las carpetas de datos y genera compose.env con secretos nuevos
./01_launch_compose.sh         # levantar
./02_ps_compose.sh             # ver estado
./03_logs_compose.sh [servicio]# ver logs (mongo, core o periphery; por defecto todos)
./04_exec_compose.sh [comando] # shell dentro de core (sh por defecto)
./05_stop_compose.sh           # parar (sin borrar datos)
./06_start_compose.sh          # volver a arrancar tras un stop
./20_destroy.sh                # borrar TODO (contenedores + datos + compose.env), pide confirmación
```

Todos los scripts pasan `--env-file compose.env` por dentro (no se llama `.env`,
así que Docker Compose no lo carga solo) — usa siempre los scripts en vez de
`docker compose` directo, o el arranque falla con variables vacías.

## URL

- **Web UI**: http://localhost:9120

## Credenciales

`00_init.sh` genera `compose.env` a partir de `compose.env.template`, con
secretos aleatorios nuevos cada vez que no exista el fichero (por ejemplo,
tras un `20_destroy.sh`) — los imprime por pantalla al generarlos. El fichero
real (`compose.env`) NO está en git (ver `.gitignore`); para volver a verlo:
`cat compose.env`.

Contiene `KOMODO_INIT_ADMIN_USERNAME`/`KOMODO_INIT_ADMIN_PASSWORD` (admin
inicial, cámbiala tras el primer login), `KOMODO_DATABASE_USERNAME`/
`KOMODO_DATABASE_PASSWORD` (credenciales de MongoDB) y
`KOMODO_WEBHOOK_SECRET`/`KOMODO_JWT_SECRET` (secretos internos). Solo aplican
en el primer arranque de cada `compose.env` — si cambias la contraseña desde
la propia UI, `compose.env` deja de reflejar la contraseña real.

## Añadir otro host Docker (otro servidor) desde la UI

Este despliegue solo trae un `periphery`, el que gestiona el Docker de la
propia máquina donde lo lances (aparece como servidor "Local"). Para que
Komodo gestione un **segundo host Docker** (otra VM, otro servidor físico...)
hace falta instalar un `periphery` ahí y darlo de alta desde `core`:

1. En la Web UI, ve a **Servers → Add Server** y crea una **onboarding key**
   (clave de un solo uso). Core genera un par de claves y te devuelve la
   clave privada **una única vez** — cópiala en ese momento, no se puede
   volver a consultar.
2. En el host nuevo, instala el agente `periphery` pasándole esa clave (por
   contenedor Docker, systemd con el binario, o script — ver
   [docs de Komodo](https://komo.do/docs/setup/connect-servers)). El agente
   necesita poder resolver/alcanzar la URL de este `core`
   (`http://<ip-de-este-host>:9120`) y montar el socket Docker del host
   nuevo (`/var/run/docker.sock`), igual que hace el `periphery` de este
   `compose.yaml`.
3. El `periphery` nuevo hace un *handshake* criptográfico contra `core` usando
   la onboarding key y aparece en **Servers** con estado `OK` una vez conectado.
4. Por defecto cada servidor tiene `auto_rotate_keys` activo, así que tras el
   alta inicial las claves se van rotando solas sin volver a tocar nada.

## Añadir un Docker Swarm desde la UI

Komodo gestiona Swarm como un recurso propio (**Swarms**), no como un
servidor más — un Swarm "apunta" a uno o varios servidores manager que ya
están dados de alta como **Servers** (con `periphery` corriendo en ellos):

1. Asegúrate de que el swarm ya existe (`docker swarm init` ejecutado en el
   manager) y de que ese/esos manager(es) están registrados como **Servers**
   en Komodo (ver sección anterior si el manager es una máquina distinta a
   la de este despliegue).
2. En la Web UI, ve a **Swarms → Add Swarm**, ponle un nombre y selecciona
   en `server_ids` el/los servidor(es) manager. Si indicas varios, Komodo
   los prueba en orden y salta al siguiente si el primero no responde
   (alta disponibilidad del propio panel, no del swarm).
3. Una vez creado, desde la lista de nodos del recurso Swarm usa el botón
   **Join** para obtener el comando `docker swarm join ...` con el token
   correspondiente, y ejecútalo en cada worker que quieras añadir al clúster.
4. Activa `send_unhealthy_alerts` si quieres que Komodo notifique cuando un
   nodo o una tarea del swarm queden en mal estado.

## Dar de alta un Stack desde Git

Un **Stack** en Komodo es un `docker-compose.yaml` desplegado y gestionado
por un `periphery`. En vez de pegar el compose a mano en la UI, lo normal es
apuntarlo a un repo Git para que Komodo lo clone/actualice y lo despliegue:

1. **Resources → Stacks → Add Stack**.
2. En **Source** elige `Git Repo` (en vez de `UI Defined`): URL del repo,
   rama, y ruta dentro del repo al fichero compose (`compose.yaml` o
   subcarpeta, si el repo tiene varios proyectos como este mismo).
3. Si el repo es privado, da de alta la credencial en
   **Settings → Git Providers** (token de GitHub/Gitea/GitLab) y selecciónala
   en el Stack — no hace falta un token embebido en la URL.
4. En **Server** elige en qué servidor (con `periphery` ya registrado) se
   despliega — ahí es donde se hace el `git clone`/`pull` y el
   `docker compose up -d`, no en `core`.
5. Pestaña **Environment**: variables de entorno del stack definidas desde la
   propia UI (Komodo las escribe a un `.env` en el host antes del deploy) —
   así los secretos no van al repo.
6. **Webhook Enabled** (en la config del Stack) da una URL de webhook propia
   de Komodo; añádela como webhook del repo en GitHub/Gitea/GitLab y cada
   `push` a la rama configurada dispara un redeploy automático.
7. **Deploy** para el primer despliegue manual; a partir de ahí, o el botón
   Deploy o el webhook mantienen el stack sincronizado con el repo.

## Builds — construir imágenes desde un Dockerfile en Git

Un **Build** hace que Komodo compile una imagen Docker desde un Dockerfile en
Git (y opcionalmente la publique en un registry), en vez de limitarse a
desplegar imágenes ya construidas:

1. **Resources → Builds → Add Build**: repo Git, rama, ruta al `Dockerfile`,
   contexto de build y build-args si los necesita.
2. **Builder**: puede ser un `Server` ya dado de alta (la imagen se construye
   ahí, con su Docker) o un *builder* efímero (p. ej. instancia AWS EC2 que
   Komodo levanta, construye y destruye sola) — según lo que tengas
   configurado en Settings.
3. **Image Registry**: credenciales del registry destino (Docker Hub, GHCR,
   registry propio) en **Settings → Registry Accounts**; el Build hace push
   ahí tras compilar.
4. Con `Auto Increment Version` activado, Komodo etiqueta cada build con una
   versión semántica incremental además de `latest`.
5. Igual que en los Stacks, se puede activar un **webhook** para que un push
   al repo dispare el build automáticamente.
6. Una vez publicada, un Stack o Deployment puede referenciar esa imagen (por
   tag o `latest`) para que Komodo la despliegue.

## Resource Sync — toda la configuración de Komodo como código

Además de que un Stack individual apunte a Git, Komodo permite declarar sus
propios recursos (Servers, Stacks, Builds, Alerters, variables compartidas...)
en ficheros `.toml` dentro de un repo, y sincronizarlos ("GitOps del propio
Komodo", no solo de los contenedores):

1. **Resources → Resource Syncs → Add Sync**, apuntando a un repo/carpeta con
   los ficheros `.toml` (formato descrito en la
   [documentación de Komodo](https://komo.do/docs)).
2. **Execute Sync** compara lo declarado en Git contra el estado real y
   muestra un diff (qué se crea/actualiza/borra) antes de aplicar nada — modo
   "plan" antes de "apply", como Terraform.
3. Útil para versionar toda la instalación de Komodo (no solo qué stacks hay
   desplegados) y poder reconstruirla desde cero a partir del repo.

## Procedures y Actions — automatizaciones encadenadas

- **Procedures** (`Resources → Procedures → New`): encadenan varias
  operaciones de Komodo en stages ordenados (desplegar stack A, esperar,
  desplegar stack B, ejecutar una Action...). Se pueden lanzar a mano, por
  webhook, o con un **schedule** tipo cron.
- **Actions** (`Resources → Actions → New`): scripts embebidos (TypeScript/
  Deno) que llaman a la propia API de Komodo para lógica a medida — por
  ejemplo "si el servidor X lleva N minutos `unreachable`, redesplegar su
  stack y avisar por Slack".

## Alertas

**Settings → Alerters → Add Alerter**: Slack, Discord, ntfy, email (SMTP) o
un webhook genérico. Cada Alerter se puede filtrar por tipo de evento
(servidor inalcanzable, cambio de estado de un contenedor, build fallido,
deployment fallido, uso de disco alto...) y opcionalmente restringir a
ciertos servidores/stacks, para no recibir ruido de todo lo que Komodo
gestiona.

## Terminal (shell del servidor / exec en un contenedor)

Desde un **Server** dado de alta, Komodo ofrece dos tipos de terminal vía su
`periphery`:

- **Terminal del host**: shell directa sobre la máquina donde corre ese
  `periphery` (no dentro de un contenedor).
- **Container Exec**: shell dentro de un contenedor concreto, eligiendo qué
  binario usar como shell (`bash`, `sh`, etc.). Si el contenedor destino es
  una imagen mínima (Alpine, distroless...) sin `bash`, hay que elegir `sh`
  explícitamente o el exec falla con "código 127" (comando no encontrado) —
  pasó justo así al probarlo contra `dashy` en este mismo host.

## Volúmenes (bind mounts locales)

Todos los datos persistentes están en subcarpetas de este mismo directorio
(no en volúmenes con nombre de Docker):

| Carpeta | Contenido |
|---|---|
| `./mongo-data` | Datos de MongoDB (`/data/db`) |
| `./mongo-config` | Configuración interna de MongoDB (`/data/configdb`) |
| `./keys` | Claves de comunicación Core ↔ Periphery (`core.key/pub`, `periphery.key/pub`) |
| `./backups` | Backups de base de datos generados por Komodo |

Nota: `mongo-data`/`mongo-config` los crea y posee el usuario interno del
contenedor de Mongo, no tu usuario — es normal no poder listarlos/borrarlos
sin `sudo` desde fuera del contenedor.

Verificado de extremo a extremo (init → launch → login real contra la API
con las credenciales generadas → stop/start → destroy → volver a empezar)
antes de dejar este ejemplo en el repo.
