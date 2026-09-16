# Servicios Docker: Zeppelin + Postgres + Hue + Adminer

Ejemplo derivado del entorno de laboratorios del curso "Python para
Auditoría" (BBK) — un notebook Zeppelin con Python moderno, una base de
datos Postgres simulando un sistema corporativo, HUE y un cliente web de
BBDD. Pensado para ejecutarse tanto en local como dentro de las imágenes de
escritorio remoto Kasm Workspaces de
[kasm-workspaces-images](https://github.com/pepesan/kasm-workspaces-images)
(variantes `*-dind`), que ya clonan este mismo repositorio.

Todos los servicios necesarios se levantan desde este `compose.yaml`.
Cualquier servicio nuevo que necesite el laboratorio se añade aquí, en vez
de crear composes sueltos por módulo.

## Uso

Además de los comandos `docker compose` directos, hay un script por acción
habitual (patrón tomado de
[docker-twitch/compose/00_basico](https://github.com/pepesan/docker-twitch/tree/main/compose/00_basico)):

```bash
cd compose/41_zeppelin
./00_init.sh                        # (solo la primera vez) crea ./volumes con los permisos correctos
./01_launch_compose.sh              # levantar todos los servicios
./02_ps_compose.sh                  # ver estado
./03_logs_compose.sh [servicio]     # ver logs (todos o de uno concreto)
./04_exec_compose.sh <servicio> [comando]   # shell dentro de un servicio (bash por defecto)
./05_stop_compose.sh [servicio ...] # parar (sin borrar contenedores/volúmenes)
./06_start_compose.sh [servicio ...]# volver a arrancar tras un stop
./20_destroy.sh                     # borrar TODO (contenedores + volúmenes), pide confirmación
```

Equivalencia directa con `docker compose`:

```bash
docker compose up -d      # levantar todos los servicios
docker compose ps         # ver estado
docker compose logs -f    # ver logs
docker compose down       # parar
docker compose down -v    # parar y borrar los datos persistidos (BBDD, notebooks)
```

## Servicios, puertos y credenciales por defecto

| Servicio  | Acceso                        | Usuario   | Contraseña | Módulo(s) |
|-----------|--------------------------------|-----------|------------|-----------|
| `zeppelin`| http://localhost:8080          | —         | —          | 1, 3, 4   |
| `db`      | `localhost:5432`, BBDD `auditoria` | `auditor` | `auditor`  | 3, 4      |
| `hue`     | http://localhost:8888          | se crea en el primer acceso (no trae usuario por defecto) | — | 3 |
| `adminer` | http://localhost:8091           | — (pide host/usuario/contraseña de `db` en el formulario) | — | 3 |

> El primer acceso a HUE pide crear un usuario y contraseña (quedan
> guardados en su propia BBDD interna `hue`, dentro del mismo servidor
> Postgres del servicio `db`, separada de `auditoria`); ese primer usuario
> se convierte en administrador. Una vez dentro, en el editor SQL **elige el
> conector "Auditoría (Postgres)"** — es el único que funciona en este
> laboratorio y apunta a la misma BBDD `auditoria` que usan los notebooks de
> Zeppelin y Adminer, sin que haga falta configurar nada más (ver
> `hue/conf/zz-course-overrides.ini`). La imagen `gethue/hue` trae también
> "Hive" e "Impala" en el desplegable por ser conectores estándar de la
> imagen, pero **no funcionan aquí** (no hay ningún HiveServer2 levantado):
> seleccionarlos da un error de conexión al puerto 10000
> (`TTransportException`). No es un fallo del laboratorio, es que esos dos
> conectores no aplican a este entorno — ignóralos.

> Son credenciales de un entorno **local de prácticas**, sin datos reales ni
> acceso a sistemas del banco. No usar este esquema de credenciales fuera del
> laboratorio.

> `adminer` usa el puerto **8091** (no el 8080/8081 más habitual) porque,
> dentro de un escritorio Kasm Workspaces, el 8081 ya lo ocupa el propio
> servicio de audio del escritorio (`kasm_audio_out`). Fuera de ese contexto
> el 8091 funciona igual de bien, así que se deja como único valor.

## Imágenes y versión

| Servicio  | Imagen                              |
|-----------|-------------------------------------|
| `zeppelin`| `pepesan/zeppelin:python-3.14` (construida de `./zeppelin/image`, ver más abajo; también en Docker Hub) |
| `db`      | `postgres:18.6`                     |
| `hue`     | `gethue/hue:20260611-140101`        |
| `adminer` | `adminer:6.0.1`                     |

`db`, `hue` y `adminer` están fijadas a un tag de versión concreto (nunca
`latest`), para que el entorno de laboratorio sea reproducible. Comprobado a
fecha 2026-09-12 contra Docker Hub — última versión etiquetada de cada imagen:

- `postgres` no publica tags posteriores a la serie `18` (`18.6`).
- `gethue/hue` no publica releases con versión semántica desde la 4.11.0
  (2021); desde entonces publica builds diarias con tag `AAAAMMDD-HHMMSS`.
  `20260611-140101` es la build más reciente con ese formato (`latest`
  apunta a la misma imagen).
- `adminer` no publica tags posteriores a `6.0.1` (mantiene también las
  ramas `5.5.1` y `4.17.1` para quien necesite una versión anterior).

Al actualizar cualquier imagen, revisar de nuevo Docker Hub y anotar aquí
la fecha de la comprobación.

## Imagen Zeppelin propia (`./zeppelin/image`)

`apache/zeppelin:0.12.1` trae el intérprete `%python` sobre Python 3.7
(entorno conda `python_3_with_R`), demasiado antiguo para las librerías
modernas de análisis de datos que necesita este laboratorio. `zeppelin/image/`
extiende esa imagen con un entorno **Python 3.14** propio, creado con `uv`
(mucho más rápido que `conda create`) e instalado en `/opt/venv-curso`,
antepuesto al `$PATH` — así tanto `%python` en los notebooks como un
`docker compose exec zeppelin python3` usan la versión nueva.

Librerías instaladas (`zeppelin/image/requirements.txt`): `pandas`, `numpy`,
`openpyxl`, `sqlalchemy`, `psycopg2-binary`, `matplotlib`, `seaborn`,
`scikit-learn` — cubre los Módulos 1 a 7 del curso.

`compose.yaml` construye esta imagen automáticamente (`build: ./zeppelin/image`)
con el nombre `pepesan/zeppelin:python-3.14` — el mismo con el que se publica
en Docker Hub, para no tener un nombre distinto en local y en remoto. No hace
falta nada manual para levantar el entorno; los scripts de `scripts/`
son solo para reconstruirla aparte o publicarla en Docker Hub:

```bash
cd scripts
./build_zeppelin_image.sh   # reconstruye pepesan/zeppelin:python-3.14 (local)
./push_zeppelin_image.sh    # la sube a Docker Hub: python-3.14 y también como "latest"
```

El `X.Y` del tag (`python-3.14`) se calcula solo a partir de la imagen ya
construida (`python3 --version` dentro de ella) — nunca se escribe a mano,
para que no se desincronice del contenido real de la imagen. `latest` es un
alias explícito hacia esa misma versión, no una imagen distinta.

## Notebooks de ejemplo (`./zeppelin/ejemplos`)

Los notebooks de ejemplo que se preparen para el curso se versionan en el
propio repositorio, en `zeppelin/ejemplos/<NN>_<modulo>/`, uno por
módulo que use Zeppelin (Módulos 1, 3 y 4):

```
zeppelin/ejemplos/
├── 01_introduccion/
├── 03_carga_datos/
└── 04_analisis_trazabilidad/
```

Esta carpeta se monta como subcarpeta de lectura/escritura dentro del
`notebook.dir` del contenedor (`/opt/zeppelin/notebook/ejemplos`), así que
Zeppelin la indexa automáticamente y aparece como una carpeta más en su UI
(`ejemplos/01_introduccion/...`) y se puede crear/editar notebooks
directamente desde el navegador — los cambios se guardan tal cual en el
repo (`zeppelin/ejemplos/...`). Distinto de los notebooks que el
alumno cree en `volumes/zeppelin/notebook/`, que no se versionan.

Al ser lectura/escritura, cualquier edición desde la UI sobre un notebook
de `ejemplos/` modifica directamente el fichero versionado — revisar con
`git diff` antes de comitear cambios hechos así.

Estado actual:

- `01_introduccion/` — completo: `00_estructura_notebook_2M1EST0001.zpln`
  (estructura de un notebook, celdas Markdown/código/resultados) y
  `01_practica_auditoria_2M1PRA0001.zpln` (práctica guiada con celdas `TODO`
  para el alumno). Ambos ejecutados y validados dentro de Zeppelin.
- `03_carga_datos/` y `04_analisis_trazabilidad/` — pendientes.

> Los ficheros `.zpln` deben nombrarse `<nombre>_<ID>.zpln` (todo lo que va
> después del último `_` es el ID que usa Zeppelin para indexar la nota; si
> no se sigue este patrón, Zeppelin corta mal el nombre y asigna un ID
> equivocado). Tras añadir o editar un `.zpln` a mano hace falta
> `docker compose restart zeppelin` para que Zeppelin lo reindexe — no hay
> endpoint de recarga en caliente en esta versión.

## Datos persistentes y permisos (`./volumes`)

Los datos de `db` y `zeppelin` se guardan en bind mounts dentro de
`volumes/` (no en volúmenes nombrados de Docker), para poder
inspeccionarlos directamente desde el host:

- `volumes/db` → datos de PostgreSQL (el contenedor corre como uid:gid `999:999`)
- `volumes/zeppelin/notebook` y `volumes/zeppelin/logs` → notebooks y logs de Zeppelin (uid `1000`, gid `0`)

Un bind mount conserva el propietario que tenga en el host, así que hace
falta crear estas carpetas con el uid/gid correcto **antes** del primer
arranque — eso es justo lo que hace `00_init.sh` (usa un contenedor
`busybox` desechable para el `chown`, sin necesitar `sudo` en el host):

```bash
./00_init.sh
./01_launch_compose.sh
```

La carpeta `volumes/` está en `.gitignore` — no se versiona.

## Nota sobre Postgres 18

Desde la serie 18, la imagen oficial de `postgres` espera el volumen de datos
montado en `/var/lib/postgresql` (no en `/var/lib/postgresql/data` como en
versiones anteriores) — cambia el formato de directorio para ser compatible
con `pg_ctlcluster`. Este compose ya usa la ruta nueva; si se ve el error
`in 18+, these Docker images are configured to store database data in a
format which is compatible with "pg_ctlcluster"...`, es que la carpeta
`volumes/db` quedó inicializada con el formato antiguo — solución:
`./20_destroy.sh`, borrar `volumes/db` y volver a ejecutar `00_init.sh` +
`01_launch_compose.sh`.

## Nota sobre HUE

La imagen `gethue/hue` arranca, por defecto, **sin ningún conector SQL
activo** (todo el bloque `[[interpreters]]` de su `hue.ini` viene comentado)
y usa **SQLite** para su propia BBDD interna (usuarios, historial,
documentos guardados). Ninguna de las dos cosas sirve para este
laboratorio:

- Sin un conector configurado, no se puede lanzar ninguna consulta desde la
  interfaz web.
- SQLite no soporta bien escrituras concurrentes; bajo Docker, con la propia
  UI de HUE lanzando peticiones en paralelo (polling de estado,
  autocompletado, historial), acaba dando errores intermitentes de
  `database is locked`.

Por eso `hue/conf/zz-course-overrides.ini` (montado en
`/usr/share/hue/desktop/conf/`, se fusiona con la config de la imagen)
añade:

1. Un conector `postgresql` (vía SQLAlchemy) apuntando a la BBDD
   `auditoria` — aparece en el editor como **"Auditoría (Postgres)"**.
2. El metastore propio de HUE (`[desktop][[database]]`) apuntando a una
   BBDD `hue` separada, en el mismo servidor Postgres (creada por
   `postgres/init/00_crear_bbdd_hue.sql`), en vez de SQLite.

La imagen sigue mostrando "Hive" e "Impala" en el desplegable del editor
(son conectores estándar de `gethue/hue`, no se pueden ocultar sin romper
la aplicación: `beeswax`, el módulo de Hive, es una dependencia interna de
Hue, no una app opcional — bloquearla vía `app_blacklist` impide arrancar
el propio servicio). **No funcionan en este laboratorio** — no hay ningún
HiveServer2 levantado — y seleccionarlos da
`TTransportException: Could not connect to ... 10000`. Usa siempre el
conector "Auditoría (Postgres)".

## Datos de carga

Los scripts SQL de `postgres/init/` se ejecutan automáticamente la primera
vez que Postgres inicializa `volumes/db` (una carpeta vacía). Para forzar
una recarga desde cero:

```bash
./20_destroy.sh
rm -rf volumes/db
./00_init.sh
./01_launch_compose.sh
```

Actualmente `postgres/init/01_placeholder.sql` es un placeholder — sustituirlo
por el esquema y los datos de ejemplo que se necesiten en cada caso.
