# Dockhand — alternativa a Portainer (sin soporte Swarm)

[Dockhand](https://dockhand.pro) es un panel de gestión Docker self-hosted:
contenedores, stacks Compose (con editor visual), despliegue desde git,
terminal y logs. Un solo contenedor, sin agentes. Licencia **Business
Source License 1.1** (no es libre de verdad, ojo con uso comercial). No
soporta Docker Swarm todavía (hay un issue abierto pidiéndolo) — para eso,
ver el ejemplo [../44_komodo](../44_komodo).

## Primer arranque — paso a paso

Dockhand **no tiene un asistente que encadene esto automáticamente**: aunque
el `compose.yaml` ya monta `/var/run/docker.sock`, no detecta ni conecta el
entorno local por sí solo. Hay que hacer estos pasos a mano, en este orden:

1. Levantar el contenedor (`./01_launch_compose.sh`) y abrir la Web UI.
   Al no haber autenticación configurada todavía, entra directo sin pedir login.
2. Crear el usuario admin: **Settings → Authentication** → definir usuario y
   contraseña. Es el único momento en que se fijan las credenciales — no hay
   ningún valor por defecto ni fichero con secretos que consultar.
3. Conectar el entorno local: **Settings → Environments** → nueva conexión,
   tipo **"Local socket"/"Direct"** → guardar. Sin este paso la UI se queda
   sin contenedores que mostrar, aunque el contenedor de Dockhand esté sano
   y el socket ya montado.
4. Verificar: la vista de contenedores debe listar ya lo que corre en el host.

## Uso

```bash
cd compose/45_dockhand
./00_init.sh                   # (solo la primera vez) crea ./data
./01_launch_compose.sh         # levantar
./02_ps_compose.sh             # ver estado
./03_logs_compose.sh           # ver logs
./04_exec_compose.sh [comando] # shell dentro del contenedor (sh por defecto)
./05_stop_compose.sh           # parar (sin borrar ./data)
./06_start_compose.sh          # volver a arrancar tras un stop
./20_destroy.sh                # borrar TODO (contenedor + ./data), pide confirmación
```

## URL

- **Web UI**: http://localhost:3002

El puerto host se cambió de 3000 (el que trae el compose oficial) a **3002**
porque 3000 y 3001 ya estaban ocupados por otros contenedores en la máquina
donde se probó — ajusta el mapeo en `compose.yaml` según lo que tengas libre.

## Credenciales

Dockhand **no trae usuario/contraseña por defecto en el compose** — se
definen en el paso 2 de arriba, la primera vez que abres la Web UI. No hay
ningún secreto que copiar de ningún fichero.

Internamente genera una clave de cifrado propia (`.encryption_key`, ver más
abajo), que no hay que tocar ni recordar: la gestiona la propia app.

## Volúmenes (bind mount local)

Todos los datos persistentes están en `./data` (en vez de un volumen con
nombre de Docker):

| Ruta | Contenido |
|---|---|
| `./data/.encryption_key` | Clave de cifrado interna generada por Dockhand |
| `./data/db` | Base de datos SQLite de Dockhand (usuarios, stacks, config) |
| `./data/git-repos` | Cachés de repos git usados por los stacks "Git-tracked" |

## Docker Swarm

Dockhand no soporta Docker Swarm (hay un issue abierto pidiéndolo, sin
implementar todavía) — gestiona contenedores y stacks Compose en hosts
individuales o multi-entorno, no clusters Swarm.

Verificado de extremo a extremo (init → launch → creación manual de admin y
entorno local → contenedores del host visibles en la UI → stop/start →
destroy → volver a empezar) antes de dejar este ejemplo en el repo.
