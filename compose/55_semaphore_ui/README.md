# Ansible Semaphore UI con Docker Compose

Laboratorio local para practicar la interfaz web de Semaphore UI y ejecutar playbooks de Ansible. Usa PostgreSQL para persistir la configuración y los datos de Semaphore. No es una configuración de producción.

La imagen, variables de configuración y cifrado siguen la [documentación oficial de instalación con Docker](https://semaphoreui.com/docs/admin-guide/installation/docker). La imagen predeterminada es `semaphoreui/semaphore:latest`; fija `SEMAPHORE_IMAGE` en `.env` a una etiqueta concreta si necesitas reproducibilidad entre actualizaciones.

## Preparación y primer arranque

Desde la raíz del repositorio:

```bash
cd compose/55_semaphore_ui
./00_init.sh
./01_launch_compose.sh
```

`00_init.sh` crea `.env` desde `.env.example` solo cuando falta y genera `secrets.env` si no existe. Ambos quedan con permisos `0600`; `secrets.env` está ignorado por Git. Genera contraseñas aleatorias para PostgreSQL y el administrador, además de `SEMAPHORE_ACCESS_KEY_ENCRYPTION` con el procedimiento oficial (`head -c 32 /dev/urandom | base64`). Si los archivos ya existen, conserva su contenido.

`01_launch_compose.sh` valida la configuración con `docker compose config -q` y levanta Semaphore y PostgreSQL. En el primer arranque, Semaphore crea el usuario administrador con las variables de `secrets.env`; ese password inicial solo se utiliza cuando la cuenta se crea por primera vez.

## Acceso

- URL local: <http://localhost:3001/> (solo escucha en `127.0.0.1`)
- Usuario inicial: `admin`
- Contraseña: valor de `SEMAPHORE_ADMIN_PASSWORD` en `secrets.env`, también mostrado por los scripts de preparación y lanzamiento.

Para elegir otro puerto, cambia `SEMAPHORE_HTTP_PORT` en `.env` y ejecuta `./06_start_compose.sh`. No uses el puerto 3000: puede estar ocupado por otro servicio local.

## Operación

```bash
./02_ps_compose.sh                 # estado de servicios
./03_logs_compose.sh               # logs de ambos servicios
./03_logs_compose.sh semaphore     # logs de Semaphore
./04_exec_compose.sh ansible --version
./05_stop_compose.sh               # detener conservando datos
./06_start_compose.sh              # volver a arrancar
./07_down_compose.sh               # quitar contenedores/red, conservar datos
./99_destroy.sh                    # borrar datos (solicita escribir DESTROY)
```

`./04_exec_compose.sh` ejecuta el comando indicado dentro del contenedor `semaphore`; por ejemplo, permite comprobar la versión de Ansible incluida en la imagen.

## Persistencia y secretos

- PostgreSQL guarda el estado persistente en `./volumes/postgres`; detener servicios o ejecutar `./07_down_compose.sh` no borra esos datos.
- `./99_destroy.sh` elimina los datos persistentes después de confirmar literalmente `DESTROY`. Conserva `.env` y `secrets.env`, por lo que un nuevo arranque mantiene las mismas credenciales y clave de cifrado.
- No elimines ni regeneres `SEMAPHORE_ACCESS_KEY_ENCRYPTION` mientras la base existente contenga credenciales cifradas: se perdería la capacidad de descifrarlas.
- Para reiniciar por completo la configuración de Semaphore, ejecuta `./99_destroy.sh` y elimina `.env` y `secrets.env` manualmente antes de `./00_init.sh`.
- Los playbooks temporales y clones de repositorios de la imagen no se persisten en `./volumes`; conserva los playbooks en un repositorio Git.
- La contraseña inicial de administrador es de laboratorio. Cámbiala desde Semaphore y no expongas este servicio a redes no confiables. Si modificas `SEMAPHORE_ADMIN_PASSWORD` después del primer arranque, eso no cambia la contraseña existente.

## Referencia oficial

- [Semaphore UI — Docker](https://semaphoreui.com/docs/admin-guide/installation/docker)
