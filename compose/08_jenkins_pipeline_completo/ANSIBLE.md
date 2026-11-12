# Guía E2E de Ansible con Jenkins

Esta guía describe cómo preparar el destino SSH, registrar las credenciales en Jenkins y ejecutar los ejemplos Ansible de la serie 70. Los pasos usan como referencia la VM Ubuntu 26.04 `lxd-vm-auto`, IP `10.207.154.161`, y el Jenkins local en `http://localhost:8082`.

La serie está numerada así: 70 instala Nginx, 71 lo desinstala, 72 instala Docker, 73 despliega MariaDB con Docker, 74 retira ese contenedor, 75 despliega MariaDB/Adminer con Compose, 76 retira la pila y 77 desinstala Docker por completo. El 77 borra contenedores, imágenes y volúmenes; no forma parte de la secuencia segura.

## 1. Preparar Jenkins y la máquina destino

Desde `compose/08_jenkins_pipeline_completo/`:

```bash
./00_init.sh
./01_launch.sh
```

Comprueba que Jenkins responde en `http://localhost:8082/`. En una instalación local recién creada, las credenciales predeterminadas son `admin` / `admin`; cámbialas si el entorno será accesible desde otras máquinas.

Para ejecutar los pipelines, el destino debe tener SSH accesible desde los agentes Jenkins y las cuentas `alumno` y `root`; `alumno` necesita `sudo` sin contraseña. El paso 14 no consulta LXD: primero prueba `root@10.207.154.161`. Si falla, solicita una IP y un usuario SSH; si tampoco puede conectar, termina con error y explica cómo preparar el destino.

Comprobaciones para el destino LXD de referencia:

```bash
lxc list lxd-vm-auto
lxc exec lxd-vm-auto -- hostname -I
lxc exec lxd-vm-auto -- getent passwd alumno
lxc exec lxd-vm-auto -- getent passwd root
lxc exec lxd-vm-auto -- systemctl is-active ssh
```

Si falta OpenSSH en esa VM:

```bash
lxc exec lxd-vm-auto -- bash -lc 'apt-get update && apt-get install -y openssh-server && systemctl enable --now ssh'
```

No confundas esta VM (`10.207.154.161`) con `jenkins-external-docker` (`10.207.154.80`), que pertenece a los ejemplos Docker externos.

## 2. Crear y cargar las claves SSH en Jenkins

El método recomendado automatiza la generación de claves, la instalación de sus claves públicas en el destino y la creación de credenciales Jenkins:

```bash
./14_create_ansible_credentials.sh
```

El script numerado `14_create_ansible_credentials.sh`:

1. Prueba SSH como `root` a la IP configurada (por defecto `10.207.154.161`), sin depender del nombre ni del estado que reporte LXD.
2. Si ese acceso falla, solicita la IP y el usuario SSH que permitan verificar y preparar el destino. En una ejecución sin terminal, se pueden pasar `ANSIBLE_LXC_IP` y `ANSIBLE_SSH_BOOTSTRAP_USER`.
3. Si no logra conectar, termina con error **antes de generar claves o crear credenciales**; indica que hay que encender/crear la máquina, activar `openssh-server`, revisar la IP y autorizar una clave SSH desde este host.
4. Comprueba que existan las cuentas `alumno` y `root`. Si el usuario de preparación no es `root`, prueba `sudo -n`; si requiere contraseña, la solicita sin mostrarla y la usa por SSH para validar sudo e instalar las claves. No la guarda en Jenkins ni en disco. Sin terminal interactiva se requiere `sudo NOPASSWD`.
5. Genera claves Ed25519 si aún no existen. Las privadas quedan en `config/ssh/`, con permisos restringidos y excluidas de Git.
6. Registra las credenciales Jenkins `ansible-lxc-ip`, `ansible-lxc-alumno-ssh` y `ansible-lxc-root-ssh`.
7. Instala **solo las claves públicas** por SSH en `~/.ssh/authorized_keys` de `alumno` y `root`. El usuario solicitado es solo para preparar el host; los Jenkinsfiles siguen usando las cuentas `alumno` y `root`.

Para un destino distinto o una ejecución sin interacción:

```bash
ANSIBLE_LXC_IP=10.0.0.25 ANSIBLE_SSH_BOOTSTRAP_USER=alumno \
  ./14_create_ansible_credentials.sh
```

El paso 14 usa la IP seleccionada para crear `ansible-lxc-ip`. Si esa credencial ya existía, no la sobrescribe: actualízala en Jenkins antes de ejecutar builds contra una IP nueva. El usuario de preparación debe poder conectar por SSH; si no es `root`, el script solicita su contraseña sudo si es necesaria. La contraseña se transmite por SSH solo para esta operación y no se almacena; sin terminal interactiva, configura `sudo NOPASSWD`.

| ID de Jenkins | Tipo | Contenido |
|---|---|---|
| `ansible-lxc-ip` | Secret text | IP del destino SSH |
| `ansible-lxc-alumno-ssh` | SSH Username with private key | Usuario `alumno` y su clave privada |
| `ansible-lxc-root-ssh` | SSH Username with private key | Usuario `root` y su clave privada |

Las claves privadas **no** se copian a la VM ni se guardan en el repositorio. Jenkins las entrega temporalmente al build con `withCredentials`; los comandos Ansible usan `--private-key` y el fichero temporal se protege con permisos `0600`.

Para comprobar o cargar las credenciales manualmente: **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**. Añade `ansible-lxc-ip` como **Secret text**. Añade las otras dos como **SSH Username with private key**, con el ID y usuario correspondientes, seleccionando **Enter directly** y pegando el contenido de `config/ssh/ansible_lxc_alumno` o `config/ssh/ansible_lxc_root`. No pegues la clave en un Jenkinsfile, en el inventario ni en Git.

### Cambiar la máquina LXC o su dirección IP

Hay tres valores distintos; no los intercambies:

- `ANSIBLE_LXC_NAME`: nombre de la instancia LXD en el host; lo usan los scripts E2E `98_test_ansible_pipelines.sh` y `99_destroy_ansible_e2e.sh`, no el paso 14 ni los builds Jenkins.
- `ANSIBLE_LXC_IP`: dirección estable y alcanzable por SSH desde los agentes Jenkins. El paso 14 la guarda en la credencial Jenkins `ansible-lxc-ip`; cada build la usa para generar `inventory.ini`.
- `ansible-lxc`: alias interno del inventario. Puede mantenerse aunque cambien el nombre LXD y la IP.

En el host LXD, comprueba el nombre y la IP efectiva:

```bash
lxc list
lxc exec lxd-vm-auto -- hostname -I
```

Si cambia la IP, configura un valor estable en la red de la VM (reserva DHCP o Netplan) y ejecuta el paso 14 con la dirección nueva; consulta el ejemplo anterior. El nombre LXD no interviene en la creación de credenciales y solo se usa en el E2E que administra la máquina local.

El paso 14 no usa `ANSIBLE_LXC_NAME`: prueba `root@IP` primero y, si no conecta, solicita IP y usuario. Para una ejecución sin terminal, pasa `ANSIBLE_LXC_IP` y `ANSIBLE_SSH_BOOTSTRAP_USER`; si el usuario necesita contraseña sudo, ejecuta el script desde una terminal o configura `sudo NOPASSWD`. La contraseña solicitada no se guarda. Verifica además que el puerto 22 sea accesible desde la red del agente Jenkins.

### Cambiar el usuario SSH y `become`

La IP es una credencial común, pero el usuario SSH y `become` están fijados por pipeline; no existen ahora variables `ANSIBLE_LXC_USER` o `ANSIBLE_BECOME`. La asignación actual es:

| Ejemplo | Usuario SSH | Privilegios |
|---|---|---|
| 70–71 | `alumno` | `--become`; requiere `sudo` sin contraseña |
| 72 | `root` | Sin `become`; conecta directamente como root |
| 73–76 | `alumno` | `--become`; requiere `sudo` sin contraseña |
| 77 | `root` | Sin `become`; conecta directamente como root |

Para usar `alumno` u otra cuenta sin privilegios en Ubuntu, la VM debe tener la cuenta, SSH por clave pública y permiso para elevar privilegios. Por ejemplo, ejecutado en el host LXD para crear `deploy`:

```bash
lxc exec lxd-vm-auto -- adduser --disabled-password --gecos '' deploy
lxc exec lxd-vm-auto -- usermod -aG sudo deploy
lxc exec lxd-vm-auto -- bash -lc \
  "printf '%s\\n' 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ansible-deploy &&
   chmod 0440 /etc/sudoers.d/90-ansible-deploy &&
   visudo -cf /etc/sudoers.d/90-ansible-deploy"
```

`NOPASSWD:ALL` da a `deploy` privilegios equivalentes a root: úsalo solo en la VM de laboratorio. Un usuario SSH nuevo también necesita una clave Jenkins y su clave pública en `~/.ssh/authorized_keys`. El paso 14 instala actualmente claves solo para `alumno` y `root`; para añadir `deploy`, amplía sus listas de cuentas y la instalación de claves, crea la credencial Jenkins `ansible-lxc-deploy-ssh` con la clave privada correspondiente y usa ese `credentialsId` en los Jenkinsfiles.

En cada Jenkinsfile afectado, cambia conjuntamente el `credentialsId` de `sshUserPrivateKey` y la opción `-u alumno`/`-u root`. Usa `--become` al conectar como usuario normal que necesite operar como root; elimínalo al conectar como `root`. Para cambiar la política, actualiza también el `become: true` del playbook si lo tiene. Los comandos actuales pasan `--become` explícitamente, por lo que una variable en `inventory.ini` no los anula. Después ejecuta `01_create.sh` del ejemplo para actualizar su definición en Jenkins.

Si el mismo Jenkinsfile debe admitir varios usuarios o políticas en tiempo de build, primero hay que parametrizarlo y validar los valores; actualmente cada ejemplo tiene un usuario y una política `become` fijos en su `Jenkinsfile`.

## 3. Entender y editar `inventory.ini`

Los Jenkinsfiles crean `inventory.ini` durante cada build, dentro del workspace de ese job. No es un fichero persistente de la VM ni un fichero que se edite a mano en el workspace: el pipeline lo vuelve a generar en cada ejecución. La plantilla actual es:

```ini
[ubuntu]
ansible-lxc ansible_host=10.207.154.161
[webservers]
ansible-lxc ansible_host=10.207.154.161
[docker]
ansible-lxc ansible_host=10.207.154.161
```

En la ejecución real la IP se sustituye por la variable `LXC_IP`, leída de `ansible-lxc-ip`. `ansible-lxc` es un alias local de inventario; la misma VM aparece en varios grupos porque los playbooks seleccionan grupos distintos:

- `ubuntu`: servidor web y comprobaciones generales.
- `webservers`: grupo disponible para los playbooks web.
- `docker`: instalación y despliegues Docker/Compose.

Si cambia el nombre o IP del destino, normalmente conserva los grupos y actualiza la credencial `ansible-lxc-ip`. Si cambia los nombres de grupo, actualiza también `hosts:` en los playbooks y los comandos `ansible ubuntu` / `ansible docker` en los Jenkinsfiles. No reemplaces el alias `ansible-lxc` sin actualizar todas sus referencias.

Los Jenkinsfiles tienen una etapa llamada `Generar inventario y ansible.cfg`; la puedes localizar en `jenkinsfile/70_*/Jenkinsfile` a `jenkinsfile/77_*/Jenkinsfile`. El host del inventario se genera así:

```ini
ansible-lxc ansible_host=$LXC_IP
```

Por ello, para cambiar el destino en esta serie actualiza la configuración usada por el script 14 y la credencial Jenkins, no una copia temporal del workspace.

## 4. Entender y editar `ansible.cfg`

También se genera en el workspace de cada build. La configuración usada por la serie es:

```ini
[defaults]
inventory = /var/jenkins_home/workspace/<job>/inventory.ini
host_key_checking = True
retry_files_enabled = False
interpreter_python = auto_silent

[ssh_connection]
pipelining = True
```

La ruta real se construye con `$WORKSPACE`:

```ini
inventory = $WORKSPACE/inventory.ini
```

- `inventory`: apunta al inventario recién generado para ese build.
- `host_key_checking = True`: SSH exige una clave de host conocida.
- `interpreter_python = auto_silent`: deja que Ansible detecte Python en el destino sin avisos repetidos.
- `pipelining = True`: reduce operaciones SSH durante la ejecución.

Cada pipeline escribe también la clave pública del host con `ssh-keyscan -H "$LXC_IP"` en `~/.ssh/known_hosts` del agente. Verifica la identidad/fingerprint del destino por un canal confiable cuando configures una VM nueva; no desactives `host_key_checking` para ocultar errores de identidad. Si una VM se recrea y cambia su clave SSH, elimina del agente la entrada antigua del host o vuelve a generar la lista de hosts conocidos.

Para cambiar opciones de Ansible, modifica el bloque generador de `ansible.cfg` en cada Jenkinsfile afectado. Estos bloques están duplicados entre los ejemplos; no edites el archivo generado en el workspace esperando que el cambio persista.

## 5. Validar SSH y ejecutar los pipelines

La preparación de credenciales valida la IP y despliega las claves públicas. Para comprobar una conexión manual desde el host Jenkins/LXD:

```bash
ssh -i config/ssh/ansible_lxc_alumno \
  -o IdentitiesOnly=yes alumno@10.207.154.161 hostname
```

La primera validación Ansible es el ejemplo 70: prueba `ansible ubuntu -m ping`, instala Nginx y verifica HTTP 200. Para conservar cada job en el dashboard, créalo y ejecútalo directamente desde su carpeta:

```bash
./jenkinsfile/70_ansible_webserver/01_create.sh
./jenkinsfile/70_ansible_webserver/02_build.sh
./jenkinsfile/70_ansible_webserver/03_check.sh
```

Repite los tres pasos con el directorio del ejemplo deseado. Ejecutar `01_create.sh` de nuevo actualiza la definición del job desde su `Jenkinsfile`; `04_delete.sh` elimina ese job.

El E2E de Jenkins es específico de Ansible; no uses `./98_test_pipelines.sh all`, que ejecuta ejemplos de otras series. Desde la raíz de este proyecto:

```bash
./98_test_ansible_pipelines.sh
```
Para usar otro destino en el E2E, pasa el nombre LXD y la IP alcanzable por el agente; si el acceso SSH root no está disponible y el runner no tiene terminal, indica también `ANSIBLE_SSH_BOOTSTRAP_USER`. El destroy recupera el nombre y la IP del estado guardado:

```bash
ANSIBLE_LXC_NAME=mi-vm ANSIBLE_LXC_IP=10.0.0.25 \
  ANSIBLE_SSH_BOOTSTRAP_USER=alumno ./98_test_ansible_pipelines.sh
```

El runner crea o actualiza los jobs 70–77 y ejecuta solo los despliegues 70, 72, 73 y 75. Deja esos jobs y servicios activos; no ejecuta los pipelines de retirada 71, 74, 76 ni 77. MariaDB del ejemplo 73 queda publicada en TCP/3306 y la del Compose 75 en TCP/3307; Adminer queda en TCP/8080.

El estado inicial del destino se guarda en `config/ansible-e2e/` (ignorado por Git). Para retirar después los despliegues E2E, restaurar el estado inicial de Nginx, borrar los jobs y desinstalar Docker únicamente si no estaba instalado antes, ejecuta:

```bash
./99_destroy_ansible_e2e.sh
```

La fase de despliegue no ejecuta el 77. El destroy solo lo invoca si Docker no existía antes del E2E y comprueba antes que no quedan contenedores, volúmenes ni imágenes ajenos a los despliegues; fuera de esa limpieza, el 77 sigue siendo destructivo.

El 77 ejecuta `docker_uninstall.yaml`, borra los datos de Docker y requiere confirmación tanto del wrapper como del parámetro `CONFIRM_DATA_LOSS`. No lo lances en una VM con contenedores o volúmenes que deban conservarse.

## 6. Diagnóstico rápido

- **`UNREACHABLE` o timeout SSH:** confirma que la VM está encendida, que la IP de `ansible-lxc-ip` coincide con `hostname -I`, que el puerto 22 es alcanzable y que `sshd` está activo.
- **`Permission denied (publickey)`:** comprueba el ID de credencial del Jenkinsfile, el usuario asociado a esa credencial y que la clave pública correspondiente aparece en `~/.ssh/authorized_keys` del usuario destino. Vuelve a ejecutar `./14_create_ansible_credentials.sh` para reinstalar claves existentes.
- **`sudo: a password is required`:** configura `alumno` para usar `sudo` sin contraseña o ejecuta el ejemplo con el usuario/root previsto por su Jenkinsfile.
- **Ansible sigue usando la IP antigua:** revisa `ansible-lxc-ip` en Jenkins. El script 14 no sobrescribe credenciales existentes automáticamente.
- **`Host key verification failed`:** valida la nueva fingerprint y elimina la entrada obsoleta de `known_hosts`; no desactives `host_key_checking`.
- **Docker/Compose no responde:** ejecuta primero el 72. Si el problema es la colección `community.docker`, los pipelines 73–76 la instalan en el agente; la dependencia Python `python3-docker` se instala en el destino.
- **Un cambio del Jenkinsfile no aparece:** ejecuta de nuevo el `01_create.sh` de ese ejemplo para actualizar el job existente.

Tras `100_destroy.sh`, Jenkins pierde sus jobs y credenciales locales; reinicia el entorno con `./00_init.sh && ./01_launch.sh` y vuelve a ejecutar `./14_create_ansible_credentials.sh` antes de los builds.