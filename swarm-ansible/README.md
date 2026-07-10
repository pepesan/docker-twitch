# Laboratorio: cluster Docker Swarm sobre LXD, con Ansible

Misma idea que [`../swarm/`](../swarm/README.md) — un cluster Docker Swarm
real de 5 nodos (3 managers + 2 workers) más un nodo Portainer, todo sobre
contenedores LXD — pero orquestado con Ansible en vez de scripts de bash con
`lxc exec` sueltos. Mismo escenario, mismas IPs, mismos recursos.

## Instalación de Ansible en el Host de Control

Para ejecutar este laboratorio, necesitas tener Ansible instalado en tu máquina de control (tu host local). En Ubuntu 24.04 y 26.04, puedes realizar la instalación mediante dos métodos principales:

> [!TIP]
> **Método Recomendado (Método A - `pipx`)**: Es la opción más limpia y recomendada para entornos de desarrollo. Instala Ansible aislado en su propio entorno virtual (evitando errores de bloqueo de PEP 668 en Ubuntu 24.04+) pero mapea los comandos en tu `$PATH` automáticamente para usarse de forma global. Además, instala la versión más reciente de PyPI.


### Método A: Última versión con Python 3 mediante pipx (Recomendado)
Debido a la directiva PEP 668 implantada a partir de Ubuntu 24.04, la instalación global directa con `pip` está bloqueada para proteger las librerías del sistema. La alternativa limpia utilizando Python 3 es usar `pipx` para instalar Ansible en su propio entorno virtual privado, exponiendo los comandos (`ansible`, `ansible-playbook`, etc.) directamente en tu terminal de forma global:

```bash
# 1. Instalar pipx
sudo apt update
sudo apt install -y pipx
pipx ensurepath

# 2. Reinicia tu terminal (o ejecuta 'source ~/.profile') e instala Ansible con dependencias:
pipx install --include-deps ansible
```

### Método B: Mediante Repositorio de Paquetes DEB (PPA Oficial)
Es la forma integrada con el gestor de paquetes del sistema (`apt`), la cual descarga la versión de lanzamiento de Ansible mantenida oficialmente:

```bash
# 1. Instalar dependencias necesarias
sudo apt update
sudo apt install -y software-properties-common

# 2. Añadir el repositorio oficial PPA de Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible

# 3. Instalar Ansible
sudo apt install -y ansible
```

## Requisitos previos

- LXD instalado y funcionando (`lxc list` debe responder).
- Imagen local `ubuntu-2404-ssh-template` con tu clave SSH ya en
  `/root/.ssh/authorized_keys` — ver [`../swarm/README.md`](../swarm/README.md#crear-la-imagen-ubuntu-2404-ssh-template-si-no-la-tienes)
  para crearla si no existe.
- Red gestionada `lxdbr0` (`lxc network list`), rango `10.207.154.0/24`.
- Ansible con las colecciones `community.general` (módulo `lxd_container`)
  y `community.docker`. Comprobar con:
  ```bash
  ansible-galaxy collection list | grep -E "community.general|community.docker"
  ```
  Si faltan: `ansible-galaxy collection install community.general community.docker`

Todo esto se comprueba automáticamente en `02_check_requisitos.yml`.

## Requisitos especiales de LXD con Ansible

Los mismos tres ajustes descubiertos en el laboratorio de bash (ver
`../swarm/README.md`), pero aquí aplicados **con el módulo
`community.general.lxd_container`** en vez de `lxc config set` +
`lxc restart`:

| Ajuste (clave `config:` del módulo) | Por qué hace falta |
|---|---|
| `security.nesting: "true"` | Sin él, cualquier `docker run`/`service create` dentro del contenedor falla con `permission denied` en un sysctl — Docker necesita poder ejecutar contenedores dentro de este contenedor LXD. |
| `linux.kernel_modules: "ip_vs,ip_vs_rr,..."` | Declara los módulos que dockerd necesita: IPVS para el routing mesh, overlay para las redes VXLAN, NAT para publicar puertos. |
| `security.privileged: "true"` | Sin él, `/proc/sys/net/ipv4/vs/conntrack` no es visible dentro del contenedor y el routing mesh falla al crear la red `ingress`. Reduce el aislamiento — válido para practicar, no para producción sin más. |

**Diferencia importante con el laboratorio de bash:** en `../swarm/`, estos
tres ajustes se aplicaban con `lxc config set` **después** de `lxc init`, y
hacía falta un `lxc restart --force` para que surtieran efecto (incluso así,
en las pruebas un `lxc restart` normal a veces dejó el contenedor con
systemd atascado a mitad de apagado — hubo que forzarlo). Con
`community.general.lxd_container`, los tres van dentro del propio diccionario
`config:` de la tarea que crea el contenedor, en la **misma** llamada que
`source:` — el contenedor nace ya con la configuración correcta y
`/proc/sys/net/ipv4/vs/conntrack` está disponible desde el primer arranque,
sin necesidad de un restart posterior. Verificado probándolo: crear un
contenedor de prueba con los tres ajustes en la tarea de creación, sin pasos
adicionales, y comprobar `/proc/sys/net/ipv4/vs/conntrack` inmediatamente
después funcionó a la primera.

### Otros detalles de `lxd_container` que hay que tener en cuenta

- **`source.alias`** para una imagen local (como `ubuntu-2404-ssh-template`)
  no necesita `server:`/`protocol:` — al omitirlos, el módulo busca la
  imagen en el propio LXD local, igual que `lxc launch <alias>` sin prefijo
  de remoto.
- **`devices.eth0.ipv4.address`** fija la IP igual que
  `lxc config device override <nombre> eth0 ipv4.address=<ip>` en bash: LXD
  reserva esa IP en el DHCP de `lxdbr0` para ese contenedor.
- **`devices.root.size`** fija la cuota de disco (necesita un `storage pool`
  que la soporte — aquí `zfs`, ya comprobado en el laboratorio de bash).
- **`wait_for_ipv4_addresses: true`** hace que la tarea no termine hasta que
  el contenedor tenga IP en `eth0` — evita una condición de carrera con la
  tarea siguiente (instalar Docker por SSH) si el contenedor tarda en
  arrancar la red.
- El módulo habla directamente con el socket de LXD
  (`unix:/var/snap/lxd/common/lxd/unix.socket` en instalaciones snap, que es
  el caso aquí) — no necesita que el binario `lxc` esté en el PATH del
  proceso de Ansible, aunque `02_check_requisitos.yml` sigue usando `lxc`
  por CLI para las comprobaciones previas.
- **Idempotencia real, comprobada**: relanzar la tarea de creación sobre un
  contenedor ya existente con la misma config no lo destruye ni lo recrea
  (`changed: false`); si cambia algo en `config:`/`devices:`, el módulo
  aplica solo esa diferencia con `PUT` a la API de LXD, sin recrear el
  contenedor. `state: stopped` / `state: absent` son igual de idempotentes
  (usados en `10_probar_caida_nodo.yml` y `20_destroy.yml`).

## Nodos del laboratorio

| Host | Rol | IP | vCPU | RAM | Disco |
|------|-----|-----|------|-----|-------|
| manager1 | Manager (líder inicial) | 10.207.154.10 | 2 | 4 GB | 40 GB |
| manager2 | Manager | 10.207.154.11 | 2 | 4 GB | 40 GB |
| manager3 | Manager | 10.207.154.12 | 2 | 4 GB | 40 GB |
| worker1 | Worker | 10.207.154.13 | 4 | 8 GB | 80 GB |
| worker2 | Worker | 10.207.154.14 | 4 | 8 GB | 80 GB |
| portainer-server | Fuera del Swarm | 10.207.154.15 | 1 | 2 GB | 20 GB |

Todo se define en `inventory.ini` (variables por host: `ansible_host`,
`lxd_cpu`, `lxd_mem`, `lxd_disk`) y `group_vars/all.yml` (imagen, red,
módulos de kernel, nombres derivados). `ansible.cfg` e `inventory.ini` viven
en esta misma carpeta — no se toca `/etc/ansible`.

## Uso

### Preparación del entorno (Utilidades opcionales)

Si estás en un host limpio o necesitas preparar los requisitos previos del laboratorio, dispones de dos playbooks auxiliares:

- **Instalar LXD con ZFS**: Si no tienes LXD o el backend ZFS configurado en tu host, puedes instalarlo automáticamente:
  ```bash
  ansible-playbook 00_instalar_lxd.yml
  ```
  *(Es idempotente: si ya lo tienes configurado, no alterará tu instalación actual. Requiere privilegios de sudo).*

- **Crear la imagen base con SSH**: Si no posees la plantilla local `ubuntu-2404-ssh-template` con tu clave inyectada:
  ```bash
  ansible-playbook 01_crear_imagen_base.yml
  ```
  *(Es idempotente: si la imagen ya existe, no la volverá a crear salvo que pases `-e force_recreate=true`).*

### Despliegue del Laboratorio

Una vez cumplidos los requisitos previos, puedes lanzar la ejecución secuencial completa con:

```bash
./run_all.sh
```

O playbook a playbook:

```bash
ansible-playbook 00_instalar_lxd.yml         # Instala LXD con ZFS local (opcional)
ansible-playbook 01_crear_imagen_base.yml    # Genera la plantilla de imagen base
ansible-playbook 02_check_requisitos.yml     # Verifica LXD, imagen y red
ansible-playbook 03_crear_nodos.yml          # Crea los 6 contenedores LXD
ansible-playbook 04_instalar_docker.yml      # Instala Docker Engine en los 6
ansible-playbook 05_swarm_init.yml           # docker swarm init en manager1; guarda los tokens
ansible-playbook 06_swarm_join_managers.yml  # Une manager2 y manager3
ansible-playbook 07_swarm_join_workers.yml   # Une worker1 y worker2
ansible-playbook 08_verificar_cluster.yml    # docker node ls — confirma los 5 nodos Ready
ansible-playbook 09_desplegar_servicio.yml   # Despliega web-demo solo en workers; prueba el routing mesh
ansible-playbook 10_probar_caida_nodo.yml    # Derriba un nodo y observa la reprogramación
ansible-playbook 11_recuperar_cluster.yml         # Reequilibra las réplicas en los workers activos
ansible-playbook 12_instalar_portainer.yml        # Instala Portainer Server (fuera del cluster)
ansible-playbook 13_instalar_agente_portainer.yml # Instala el Agente y registra el cluster en Portainer
```

Todos los playbooks son idempotentes: se pueden relanzar sin que fallen ni
dupliquen nada (ver comentarios en cada fichero — `register`/`when` para las
comprobaciones de estado de Swarm, módulos idempotentes de Ansible para todo
lo demás).

### Probar la caída de un nodo con otro objetivo

```bash
ansible-playbook 10_probar_caida_nodo.yml -e target_node=manager1
# Con manager1 caído, manager2 o manager3 asumen el liderazgo (2/3 = quórum)
```

### Conectar Portainer al cluster

Tras `12_instalar_portainer.yml` y `13_instalar_agente_portainer.yml`:

1. Abrir `https://10.207.154.15:9443` e iniciar sesión.
   * **Credenciales preconfiguradas**: Usuario: `admin` | Contraseña: `mipass12345678`
2. El cluster Swarm ya estará automáticamente configurado y conectado como el entorno **`Swarm Cluster`**. No hace falta añadirlo de forma manual.

> [!NOTE]
> La contraseña de administrador se preconfigura automáticamente en el paso 12 mediante un hash Bcrypt. El registro del agente en el paso 13 se realiza de forma automatizada mediante llamadas a la API REST de Portainer. Esto evita por completo tener que registrar la contraseña o el entorno de forma manual.

## Destruir el laboratorio

Para realizar una limpieza completa y ordenada de forma automática (desinstalar Portainer y destruir todos los nodos LXD), ejecuta:

```bash
./destroy_all.sh
```

O si prefieres realizar el proceso paso a paso de forma manual:

```bash
# 1. Elimina Portainer Agent y su red overlay del cluster Swarm
ansible-playbook 18_desinstalar_agente_portainer.yml

# 2. Elimina Portainer Server y su volumen de datos
ansible-playbook 19_desinstalar_portainer.yml

# 3. Destruye los nodos LXD y limpia tokens
ansible-playbook 20_destroy.yml
```

O si prefieres destruir directamente los nodos LXD sin desinstalar Portainer previamente (por ejemplo, si no necesitas limpiar los volúmenes de Docker de forma ordenada):

```bash
ansible-playbook 20_destroy.yml
```

Todos estos métodos piden confirmación explícita (escribir `si`) antes de proceder con el borrado.

## Notas

- Los tokens de unión (`manager.token`, `worker.token`) se guardan en esta
  carpeta (`.gitignore` los excluye) y los lee `lookup('file', ...)` en los
  playbooks de join — no hace falta pasarlos a mano entre nodos.
- `pipelining = True` en `ansible.cfg` acelera la ejecución contra los 6
  nodos (ver comentario en el propio fichero).
- Diferencias frente a `../swarm/`: aquí la conexión a los nodos es por SSH
  estándar de Ansible (`ansible_user: root`, clave ya en la imagen), no por
  `lxc exec`; la creación/parada/borrado de contenedores LXD se hace con el
  módulo `community.general.lxd_container` hablando directo con la API de
  LXD, no con el binario `lxc`.
