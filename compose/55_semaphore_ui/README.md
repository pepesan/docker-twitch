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

## URL y credenciales

La salida de `./00_init.sh` y `./01_launch_compose.sh` muestra la URL y los datos de acceso. Para volver a consultarlos, desde esta carpeta ejecuta:

```bash
./00_init.sh
```

`00_init.sh` no inicia ni detiene contenedores. Si `.env` y `secrets.env` ya existen, los conserva y muestra la contraseña inicial guardada; no genera credenciales nuevas.

Con la configuración predeterminada verás:

```text
Admin Semaphore: admin / <contraseña-inicial>
URL local: http://localhost:3001/
```

La cuenta web usa `SEMAPHORE_ADMIN_USER` de `.env` (por defecto, `admin`) y la contraseña `SEMAPHORE_ADMIN_PASSWORD` de `secrets.env`. El usuario y la contraseña de PostgreSQL son distintos; no se usan para iniciar sesión en la web.

La URL predeterminada es `http://localhost:3001/` y solo escucha en `127.0.0.1`, así que ábrela en un navegador del mismo equipo. Si cambias `SEMAPHORE_HTTP_PORT` en `.env`, usa el puerto que indique `00_init.sh` o `01_launch_compose.sh` y aplica el cambio ejecutando `./06_start_compose.sh`.

La contraseña que muestra `00_init.sh` es la contraseña de bootstrap. Si la cambiaste dentro de Semaphore, el fichero local conserva el valor inicial y no puede mostrar la contraseña nueva. Para recuperar el acceso tras perder la contraseña modificada, el reinicio completo descrito en «Persistencia y secretos» borra también proyectos, inventarios y credenciales guardadas.

No compartas ni publiques la salida con la contraseña. `.env`, `secrets.env` y los datos de PostgreSQL están excluidos de Git.

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

## Laboratorio E2E de Ansible

`80_deploy_semaphore_with_examples.sh` arranca Semaphore, prepara un usuario y proyecto E2E, carga la clave SSH, el repositorio `pepesan/ejemplos-ansible`, el inventario de la LXC y las plantillas de despliegue/retirada. Ejecuta y verifica esta secuencia:

1. Instala el servidor web y luego lo desinstala.
2. Instala Docker.
3. Despliega el contenedor Docker de Nginx y lo retira antes de Compose: ambos ejemplos publican el puerto 81 y no pueden ejecutarse a la vez.
4. Despliega WordPress con Docker Compose. Al terminar, queda disponible en `http://<IP_LXC>:81/`.

Antes de lanzarlo, revisa `e2e.env` (host, usuario SSH, clave privada y rama Git). Si falta, el script lo crea desde `e2e.env.example` y se detiene para que confirmes esos valores; vuelve a ejecutarlo tras revisarlos. La contraseña del usuario E2E se genera en `e2e-secrets.env`. Ambos ficheros están ignorados por Git. El script actualiza las rutas de playbook de las plantillas existentes y conserva los IDs, recursos e historial.

```bash
./80_deploy_semaphore_with_examples.sh
```

Para ejecutar el ciclo completo, incluida la retirada de Compose y la desinstalación de Docker, usa `90_e2e.sh`. **Borra `/var/lib/docker`, `/var/lib/containerd` y `/etc/docker`, incluidos datos Docker ajenos al ejemplo.** Solo debe usarse con una LXC desechable y después de verificar que Docker no contiene datos que conservar:

```bash
E2E_CONFIRM_DOCKER_PURGE=YES ./90_e2e.sh
```

La prueba completa deja la LXC sin Docker ni Nginx, pero conserva en Semaphore el proyecto, las plantillas y el historial de ejecuciones.

## Persistencia y secretos

- PostgreSQL guarda el estado persistente en `./volumes/postgres`; detener servicios o ejecutar `./07_down_compose.sh` no borra esos datos.
- `./99_destroy.sh` elimina los datos persistentes después de confirmar literalmente `DESTROY`. Conserva `.env` y `secrets.env`, por lo que un nuevo arranque mantiene las mismas credenciales y clave de cifrado.
- No elimines ni regeneres `SEMAPHORE_ACCESS_KEY_ENCRYPTION` mientras la base existente contenga credenciales cifradas: se perdería la capacidad de descifrarlas.
- Para reiniciar por completo la configuración de Semaphore, ejecuta `./99_destroy.sh` y elimina `.env` y `secrets.env` manualmente antes de `./00_init.sh`.
- Los playbooks temporales y clones de repositorios de la imagen no se persisten en `./volumes`; conserva los playbooks en un repositorio Git.
- La contraseña inicial de administrador es de laboratorio. Cámbiala desde Semaphore y no expongas este servicio a redes no confiables. Si modificas `SEMAPHORE_ADMIN_PASSWORD` después del primer arranque, eso no cambia la contraseña existente.

## Referencia oficial

- [Semaphore UI — Docker](https://semaphoreui.com/docs/admin-guide/installation/docker)
