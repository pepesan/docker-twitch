# AWX (rama de desarrollo, devel) con docker compose

Entorno de **desarrollo** de AWX (repo [ansible/awx](https://github.com/ansible/awx),
rama `devel`), levantado con un `compose.yaml` propio de este ejemplo
(no el `docker-compose.yml` que genera el `Makefile` del repo, aunque se
basa en él) usando una imagen propia construida localmente y publicada
en Docker Hub.

**Aviso oficial del propio repo**: desplegar desde `devel`/HEAD no es
estable — es la rama de desarrollo activo, no una release.

## Requisito previo: tener la imagen

Para arrancar el ejemplo hace falta la imagen de [.env](.env)
(`AWX_IMAGE`). Dos opciones:

- Ya está publicada en Docker Hub (o ya la tienes en local de una vuelta
  anterior) → ve directo a "1. Lanzar el entorno".
- Hay que construirla desde el código fuente de `ansible/awx` → ve
  primero a la sección "Descarga de fuentes, build y publicación de la
  imagen" más abajo, y vuelve aquí cuando termine.

## 1. Lanzar el entorno

```shell
./00_init.sh              # crea ./volumes y ./secrets.env (contraseñas) si no existen
./01_launch_compose.sh    # docker compose up -d (awx + redis + postgres)
./02_create_admin.sh      # fija la password del admin
./08_build_ui.sh          # compila la UI real (solo falta la primera vez)
```

Todos son idempotentes: puedes volver a ejecutarlos sin que rompan nada
si el entorno ya estaba levantado.

- `00_init.sh`: si no existe `secrets.env`, genera contraseñas
  aleatorias (`AWX_PG_PASSWORD`, `AWX_ADMIN_PASSWORD`) y las imprime por
  pantalla; crea `./volumes/awx_db` y `./volumes/redis_socket`. **No**
  toca el código de `ansible/awx` ni la imagen — para eso ver la otra
  sección.
- `01_launch_compose.sh`: `docker compose up -d`. La primera vez tarda
  varios minutos (migraciones de base de datos y bootstrap de
  desarrollo dentro del contenedor `awx`). Al terminar recuerda la URL
  y las credenciales. Ese bootstrap ya crea el usuario `admin` y los
  datos de ejemplo automáticamente, pero sin una contraseña usable
  (depende de una variable de entorno que no se fija en
  `compose.yaml`) — por eso hace falta el siguiente paso.
- `02_create_admin.sh`: fija la contraseña del usuario `admin` con
  `awx-manage changepassword admin`, al valor de `secrets.env`
  (`AWX_ADMIN_PASSWORD`).
- `08_build_ui.sh`: el bootstrap, si no encuentra un build real,
  genera solo un **placeholder** de la UI (verás "the UI wasn't
  properly built" en el navegador). La UI de verdad vive en un repo
  aparte ([ansible/ansible-ui](https://github.com/ansible/ansible-ui))
  y hay que compilarla aparte: este script entra en el contenedor `awx`
  (que ya trae Node 18, lo que exige su propio `Makefile`), clona
  `ansible-ui`, hace `npm install` + build con webpack, y reinicia
  `awx` para que nginx/uwsgi sirvan los estáticos nuevos. Tarda varios
  minutos. Hay que repetirlo si reconstruyes la imagen desde cero o
  borras `awx/awx/ui/build` a mano.

## 2. Acceso

- UI / API: [https://localhost:8043/](https://localhost:8043/)
  (puerto configurable en [.env](.env) como `AWX_HTTPS_PORT`)
- Login: `admin` / el valor de `AWX_ADMIN_PASSWORD` en `secrets.env`
  (impreso por `./00_init.sh` y recordado por `./01_launch_compose.sh`)

## 3. Gestión del día a día

- `./03_preload_demo_data.sh` — opcional: organización/proyecto/inventario
  demo (ya se carga sola en el primer arranque)
- `./04_ps_compose.sh` — estado de los contenedores
- `./05_logs_compose.sh [servicio]` — logs (`awx`, `postgres`, `redis`)
- `./06_stop_compose.sh` / `./07_start_compose.sh` — parar/arrancar sin
  borrar datos

## 4. Destruir el entorno

```shell
./20_destroy.sh
```

Pide confirmación y hace `docker compose down --remove-orphans` + borra
`./volumes` (datos de postgres y socket de redis) y el directorio
`./awx` clonado (repo + configuración renderizada, incluye `SECRET_KEY`
y contraseñas generadas en `database.py`). **Conserva** `secrets.env`
(mismas credenciales en el próximo `./00_init.sh`; bórralo a mano si
quieres contraseñas nuevas) y **no** borra la imagen ya publicada en
Docker Hub. Irreversible.

---

## Descarga de fuentes, build y publicación de la imagen

Solo hace falta repetir esto cuando quieras una imagen nueva (código
más reciente de `ansible/awx`, o una versión/tag distinta en
[.env](.env)).

### Instalación de software necesario en la máquina (una sola vez)

```shell
./scripts/00_install_prerequisites.sh
```

Con permisos de sudo. Instala `git`, `make`, `python3-pip`, el plugin
`docker compose` y, vía `pip3 --user`, `ansible-core` + las colecciones
`community.docker`, `community.general` y `ansible.posix` (las usan los
playbooks internos de `ansible/awx` para renderizar la configuración).
Docker debe estar ya instalado, con el usuario en el grupo `docker`.

### Clonar/actualizar fuentes, compilar y publicar

```shell
./scripts/01_clone_awx_devel.sh   # clona ansible/awx (rama devel) en ./awx, o lo actualiza si ya existe
./scripts/02_build_image.sh       # make docker-compose-build + docker-compose-sources, re-etiqueta la imagen
docker login                      # una sola vez, con tu cuenta de Docker Hub
./scripts/03_push_image.sh        # docker push de la imagen ya etiquetada
```

- `01_clone_awx_devel.sh`: **idempotente pero siempre al día con
  origen** — si `./awx` no existe lo clona; si ya existe, hace `git
  fetch` + `git reset --hard origin/devel` para traer siempre los
  últimos cambios de la rama `devel` (no se limita a saltarse el paso).
  No toca los artefactos generados por nosotros (UI compilada, config
  renderizada en `_sources/`), solo el código fuente versionado del
  repo.
- `02_build_image.sh`: ejecuta `make docker-compose-build` (build con
  BuildKit a partir de `Dockerfile.dev`, imagen resultante siempre
  `ghcr.io/ansible/awx_devel:devel` — es el nombre fijo que usa el
  propio `Makefile`) y `make docker-compose-sources` (renderiza
  `SECRET_KEY`, `database.py`, `nginx.conf`, `receptor.conf`... en
  `awx/tools/docker-compose/_sources/`, que es lo que monta el
  `compose.yaml` de este ejemplo). Fija la password de Postgres dentro
  de `database.py` al valor de `secrets.env` (`AWX_PG_PASSWORD`) para
  que coincida siempre con el servicio `postgres`. Al final re-etiqueta
  la imagen con el nombre de [.env](.env) (`AWX_IMAGE`). Volver a
  ejecutarlo tras cambiar `AWX_TAG`/`AWX_IMAGE` en `.env` genera una
  imagen nueva con ese nombre sin afectar a las anteriores.
- `03_push_image.sh`: hace `docker push` de esa imagen. Requiere haber
  hecho `docker login` a mano antes (este script nunca introduce
  credenciales).

Los nombres de usuario/imagen/tag se configuran en [.env](.env)
(`AWX_DOCKERHUB_USER`, `AWX_IMAGE_NAME`, `AWX_TAG`, `AWX_IMAGE`). Para
publicar una versión nueva, cambia `AWX_TAG` (y `AWX_IMAGE` a juego) y
repite `02_build_image.sh` + `03_push_image.sh`.

### Contraseñas: `secrets.env`

[.env](.env) solo tiene configuración no sensible (puertos, nombre de
imagen...) y se versiona en git. Las contraseñas (`AWX_PG_PASSWORD`,
`AWX_ADMIN_PASSWORD`) viven en **`secrets.env`**, ignorado por git
([.gitignore](.gitignore)): `./00_init.sh` lo genera la primera vez con
valores aleatorios (`openssl rand -hex`) si no existe. Para verlas en
cualquier momento: `cat secrets.env`.

### Notas

- El contenedor `awx` monta el código fuente de `./awx` como volumen
  (`./awx:/awx_devel`), igual que el entorno de desarrollo oficial — es
  cómo funciona este modo "devel" (recarga en caliente, migraciones en
  arranque). La imagen por sí sola no es un AWX autocontenido para
  producción; sigue haciendo falta el directorio `awx/` clonado junto
  al `compose.yaml`.
- Los datos persistentes (base de datos de postgres, socket de redis)
  se guardan en bind mounts dentro de `./volumes/`, no en volúmenes
  nombrados de Docker — así están a la vista junto al resto del
  ejemplo. Los tres servicios (`awx`, `postgres`, `redis`) usan la red
  `default` que `docker compose` crea automáticamente para el
  proyecto, sin redes nombradas a mano.
- `postgres` usa la imagen oficial `postgres:17` (no la
  `quay.io/sclorg/postgresql-15-c9s` que trae por defecto el
  `docker-compose.yml` que genera el propio repo de AWX — esa es más
  vieja y no hay build 17 publicado de esa variante sclorg). Si cambias
  de versión mayor de Postgres, borra `./volumes/awx_db` antes de
  relanzar: el formato de datos en disco no es compatible entre
  versiones mayores.
