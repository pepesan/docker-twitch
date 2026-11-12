# AWX en una versión publicada (tag) con docker compose

Entorno de **laboratorio** de AWX ([ansible/awx](https://github.com/ansible/awx)) fijado a un **tag publicado**
(`AWX_REF` en [.env](.env)), no a la rama `devel`. Es una copia adaptada de `49_awx`:
usa el mismo modo «entorno de desarrollo» del repositorio de AWX (imagen `Dockerfile.dev`, código montado desde `./awx`),
pero con el código de una release, de modo que dos construcciones en fechas distintas dan la misma versión.

No es una instalación para producción.

## Diferencias con `49_awx`

| | `49_awx` | `56_awx_stable` |
|---|---|---|
| Código de AWX | rama `devel` (`reset --hard origin/devel` en cada ejecución) | tag `AWX_REF` (`git checkout` del tag) |
| Imagen local | `ghcr.io/ansible/awx_devel:devel` | `ghcr.io/ansible/awx_devel:<AWX_REF>` |
| Contenedores | `awx`, `awx_redis`, `awx_postgres` | `awx_stable`, `awx_stable_redis`, `awx_stable_postgres` |
| Puertos | 8013 / 8043 | 8014 (HTTP) / 8044 (HTTPS) |
| PostgreSQL | 17 | 15 |
| Compilar la UI | `make ui` | `make ui-devel` |

## Uso

```bash
./00_init.sh            # genera secrets.env, clona el tag y compila la imagen
./01_launch_compose.sh  # levanta awx, redis y postgres (la primera vez ejecuta las migraciones)
./02_create_admin.sh    # fija la contraseña del usuario admin (solo cuando ya existe)
./08_build_ui.sh        # compila la interfaz web (sin esto solo hay un placeholder)
```

La URL es `https://localhost:8044/` (certificado autofirmado) y el usuario `admin`. La contraseña está en `secrets.env`
(no se versiona).

`02_create_admin.sh` solo funciona cuando las migraciones terminaron y el usuario `admin` ya existe.

Parar y arrancar: `./06_stop_compose.sh` / `./07_start_compose.sh` (conservan datos y UI). Destruir todo el laboratorio (contenedores, datos y clon de AWX): `./97_destroy_lab.sh`.

### Reproducibilidad: ajuste de `openssl`

El `Dockerfile` de algunas releases fija el paquete `openssl-3.0.7`, que el repositorio actual de CentOS Stream 9 ya no ofrece,
y la compilación falla en `dnf install`. `scripts/01_clone_awx.sh` quita esa versión fija del fichero
`tools/ansible/roles/dockerfile/templates/Dockerfile.j2` del clon (no toca el código de AWX).

## Recursos de ejemplo y despliegues por API

Los scripts numerados a partir de `10` crean en AWX los recursos necesarios y ejecutan despliegues sobre una máquina destino
por SSH. Siguen la misma numeración que el laboratorio `55_semaphore_ui`.

```bash
cp e2e.env.example e2e.env     # revisa IP, usuario y ruta de la clave privada
chmod 600 e2e.env
./80_deploy_awx_with_examples.sh
```

`e2e.env`, `e2e-secrets.env` y `.e2e-state/` no se versionan. La clave privada se lee de su fichero, viaja a AWX por la
entrada estándar de `curl` (no aparece en `ps`) y AWX la guarda cifrada: la API devuelve `$encrypted$`.

| Script | Qué hace en AWX | En `55_semaphore_ui` |
|---|---|---|
| `10_create_user.sh` | Cuenta `ansible_e2e` que lanza las plantillas | `10` |
| `11_create_organization.sh` | Localiza la organización `Default` | `11_create_project.sh` |
| `12_add_user_to_organization.sh` | Añade la cuenta a la organización | `12_add_user_to_project.sh` |
| `13_create_credential.sh` | Credencial **Machine**: usuario, clave SSH y `sudo` | `13_create_ssh_key.sh` |
| `14_create_project.sh` | Proyecto Git (rama `master`) y su sincronización | `14_create_repository.sh` |
| `15_create_inventory.sh` | Inventario con el host y los grupos `ubuntu` y `docker` | `15` |
| `16_create_templates.sh` | 8 plantillas con la credencial enlazada y rol *Execute* | `16` |
| `17_check_e2e_resources.sh` | Comprueba los recursos y hace un ping *ad hoc* desde AWX | `17` |
| `18` / `19` | Instalar / desinstalar el servidor web | `18` / `19` |
| `20_install_docker.sh` | Instalar Docker (se niega si ya hay Docker o sus datos) | `20` |
| `21` / `22` | Desplegar / retirar un contenedor nginx (puerto 81) | `21` / `22` |
| `23` / `24` | Desplegar / retirar WordPress con Compose (puerto 81) | `23` / `24` |
| `25_uninstall_docker.sh` | Desinstalar Docker (**borra `/var/lib/docker`**) | `25` |
| `80_deploy_awx_with_examples.sh` | Levanta AWX y crea los recursos (10–17) | `80` |
| `90_e2e.sh` | Ciclo 18→25 completo | `90` |
| `98_reset.sh` | Deja AWX y el destino como recién instalados | — |
| `99_destroy.sh` | Elimina de AWX los recursos creados por estos scripts (no destruye el laboratorio: para eso, `97_destroy_lab.sh`) | `99` |

Cada script crea o reutiliza por nombre, así que se puede repetir. Los de 18 a 25 guardan un marcador en `.e2e-state/` y se
niegan a ejecutarse fuera de orden. `25` y `90_e2e.sh` borran los datos de Docker del destino: exigen
`E2E_CONFIRM_DOCKER_PURGE=YES` y solo continúan si el destino estaba limpio antes de instalar Docker.
`98_reset.sh` también desinstala nginx y Docker del destino: úsalo solo con una máquina de laboratorio desechable.

### Lo que hay que saber de los playbooks

1. **AWX no lista los playbooks de un directorio `tasks/`.** Los de `14_docker/tasks/` no se pueden elegir en una plantilla
   (la API responde *Playbook not found for project*). El repositorio `ejemplos-ansible` incluye envoltorios en
   `14_docker/awx/` con una única línea `import_playbook: ../tasks/<nombre>.yaml`.
2. **La imagen de ejecución no incluye `community.docker`.** El proyecto la declara en `collections/requirements.yml` y AWX la
   instala al sincronizar.
3. **Privilegios.** Los playbooks de Docker no declaran `become`: dependen de *Privilege Escalation* en la plantilla.

## Tiempos medidos

Una única medición en un equipo de 32 CPU, con las capas de Docker ya en caché y la LXC de destino en local. Son
referencias, no garantías: en frío (sin capas en caché) la compilación de la imagen tarda bastante más.

| Paso | Duración |
|---|---|
| `00_init.sh` (clonar el tag y compilar la imagen) | 3 min 18 s |
| `01_launch_compose.sh` | 6 s |
| Primer arranque hasta que existe el usuario `admin` (migraciones) | 2 min 2 s |
| `02_create_admin.sh` | 2 s |
| `08_build_ui.sh` (webpack) | 3 min 41 s |
| La UI responde tras `08_build_ui.sh` | ≈ 36 s |
| `80_deploy_awx_with_examples.sh` completo desde cero (incluye 00, 01, 02, 08 y los recursos 10–17) | 9 min 58 s |
| `90_e2e.sh` (instalar y retirar servidor web, Docker, contenedor y Compose) | 3 min 32 s |

Dentro del ciclo `90_e2e.sh`, cada plantilla tarda entre unos segundos y algo más de un minuto; la primera descarga la
imagen del Execution Environment.
