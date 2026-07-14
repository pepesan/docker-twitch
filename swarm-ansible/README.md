# Laboratorio: cluster Docker Swarm sobre LXD, con Ansible

Misma idea que [`../swarm/`](../swarm/README.md) — un cluster Docker Swarm
real de 5 nodos (3 managers + 2 workers) más un nodo Portainer y 2 balanceadores de carga en alta disponibilidad (active-passive), todo sobre
contenedores LXD — pero orquestado con Ansible en vez de scripts de bash con
`lxc exec` sueltos. Mismo escenario, mismas IPs, mismos recursos.

## Mapa de Servidores del Laboratorio

### Máquinas

| Máquina / Recurso | Dirección IP | Rol / Función | Recursos (CPU/MEM/Disk) |
|---|---|---|---|
| **manager1** | `10.207.154.10` | Líder inicial del cluster Swarm | 2 vCPU / 4 GB / 40 GB |
| **manager2** | `10.207.154.11` | Manager del cluster Swarm | 2 vCPU / 4 GB / 40 GB |
| **manager3** | `10.207.154.12` | Manager del cluster Swarm | 2 vCPU / 4 GB / 40 GB |
| **worker1** | `10.207.154.13` | Worker del cluster Swarm | 4 vCPU / 8 GB / 80 GB |
| **worker2** | `10.207.154.14` | Worker del cluster Swarm | 4 vCPU / 8 GB / 80 GB |
| **portainer-server** | `10.207.154.15` | Portainer y pila de observabilidad | 1 vCPU / 2 GB / 20 GB |
| **lb1** | `10.207.154.16` | HAProxy + Keepalived (MASTER) | 1 vCPU / 2 GB / 20 GB |
| **lb2** | `10.207.154.17` | HAProxy + Keepalived (BACKUP) | 1 vCPU / 2 GB / 20 GB |
| **VIP** | `10.207.154.20` | IP flotante de entrada HA | N/A |

### Servicios y accesos

| Servicio | URL / endpoint | Credenciales |
|---|---|---|
| Aplicación web HA | `https://10.207.154.20/` | No requiere; certificado autofirmado |
| Aplicación web HTTP | `http://10.207.154.20/` | No requiere; redirige a HTTPS |
| Aplicación vía routing mesh | `http://10.207.154.10:8080/` a `http://10.207.154.14:8080/` | No requiere |
| Portainer | `https://10.207.154.15:9443` | `admin` / `mipass12345678` |
| Portainer (interfaz legado) | `http://10.207.154.15:9000` | `admin` / `mipass12345678` |
| Túnel Edge de Portainer | `10.207.154.15:8000` | Endpoint de túnel, no interfaz web |
| Grafana | `http://10.207.154.15:3000` | `admin` / `mipass12345678` |
| Prometheus | `http://10.207.154.15:9090` | No requiere |
| Loki API | `http://10.207.154.15:3100` | No requiere |
| Estadísticas HAProxy | `http://10.207.154.20:1936/` | No requiere |
| Métricas HAProxy | `http://10.207.154.16:8404/metrics` y `http://10.207.154.17:8404/metrics` | No requiere |
| Métricas Docker | `http://10.207.154.10:9323/metrics` a `http://10.207.154.14:9323/metrics` | No requiere |
| Node Exporter | `http://10.207.154.10:9100/metrics` a `http://10.207.154.14:9100/metrics` | No requiere |
| cAdvisor | `http://10.207.154.10:9338/metrics` a `http://10.207.154.14:9338/metrics` | No requiere |
| Promtail | `http://10.207.154.10:9080/metrics` a `http://10.207.154.17:9080/metrics` | No requiere |

### Arquitectura

```text
                         +-----------------------+
                         | Client / browser      |
                         +-----------+-----------+
                                     |
                          HTTPS :443 | HTTP :80 -> HTTPS
                                     |
                    +----------------v----------------+
                    | VIP 10.207.154.20               |
                    +----------------+----------------+
                                     |
              +----------------------+----------------------+
              |                                             |
  +-----------v-----------+                     +-----------v-----------+
  | lb1                    |                     | lb2                  |
  | 10.207.154.16          |                     | 10.207.154.17        |
  | HAProxy + Keepalived   |<----- VRRP -------->| HAProxy + Keepalived |
  | MASTER (active)        |                     | BACKUP (standby)     |
  +-----------+-----------+                     +-----------------------+
              |
              | HAProxy -> web-demo :8080
              |
  +-----------v-------------------------------------------------------+
  | Docker Swarm                                                      |
  | managers: manager1 (.10), manager2 (.11), manager3 (.12)          |
  | workers:  worker1 (.13), worker2 (.14)                            |
  | web-demo: 3 replicas; Node Exporter; cAdvisor; Docker metrics     |
  +-----------+-------------------------------------------------------+
              | metrics / logs
              |
  +-----------v-------------------------------------------------------+
  | portainer-server 10.207.154.15                                    |
  | Portainer :9443   Grafana :3000   Prometheus :9090   Loki :3100   |
  | Prometheus scrapes HAProxy and Swarm metrics                      |
  | Grafana queries Prometheus and Loki                               |
  | Promtail on Swarm and load balancers sends logs to Loki           |
  +-------------------------------------------------------------------+
```


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
  contenedor. `state: stopped` y `state: absent` son igualmente idempotentes.

Todo se define en `inventory.ini` (variables por host: `ansible_host`,
`lxd_cpu`, `lxd_mem`, `lxd_disk`) y `group_vars/all.yml` (imagen, red,
`lb_vip`, módulos de kernel, nombres derivados). `ansible.cfg` e `inventory.ini` viven
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
ansible-playbook 02_check_requisitos.yml     # Verifica LXD, imagen y red
ansible-playbook 03_crear_nodos.yml          # Crea los 8 contenedores LXD (Swarm + Portainer + LBs)
ansible-playbook 04_instalar_docker.yml      # Instala Docker Engine en los nodos (excluye balanceadores)
ansible-playbook 05_swarm_init.yml           # docker swarm init en manager1; guarda los tokens
ansible-playbook 06_swarm_join_managers.yml  # Une manager2 y manager3
ansible-playbook 07_swarm_join_workers.yml   # Une worker1 y worker2
ansible-playbook 08_verificar_cluster.yml    # docker node ls — confirma los 5 nodos Ready
ansible-playbook 09_desplegar_servicio.yml   # Despliega web-demo (python:alpine) y expone en workers
ansible-playbook 10_probar_caida_nodo.yml    # Derriba un nodo de Swarm y observa la reprogramación
ansible-playbook 11_recuperar_cluster.yml    # Reequilibra las réplicas en los workers activos
ansible-playbook 12_instalar_portainer.yml   # Instala Portainer Server (fuera del cluster)
ansible-playbook 13_instalar_agente_portainer.yml # Instala el Agente y registra el cluster en Portainer
ansible-playbook 14_instalar_haproxy_keepalived.yml # Instala HAProxy + Keepalived (SSL y redirección)
ansible-playbook 15_probar_caida_balanceador.yml    # Simula caída de lb1 y verifica failover de VIP
ansible-playbook 16_instalar_monitorizacion.yml     # Levanta Prometheus + Grafana y configura Docker/HAProxy
ansible-playbook 17_generar_trafico.yml             # Generador de tráfico HTTP asíncrono para llenar métricas
ansible-playbook 18_instalar_loki_logs.yml          # Agrega Loki y Promtail para la centralización de logs
```

Todos los playbooks son idempotentes: se pueden relanzar sin que fallen ni
dupliquen nada.

### Probar la caída de un nodo con otro objetivo

```bash
ansible-playbook 10_probar_caida_nodo.yml -e target_node=manager1
# Con manager1 caído, manager2 o manager3 asumen el liderazgo (2/3 = quórum)
```

### Balanceo de Carga con Redundancia y Terminación SSL (HAProxy + Keepalived)

En el paso 14:
- Se instalan HAProxy y Keepalived en los nodos `lb1` y `lb2`.
- Se genera un certificado autofirmado en `localhost` y se instala para habilitar **Terminación SSL/TLS** en el puerto `443` de la VIP.
- Se configura una redirección `301` de HTTP (puerto `80`) a HTTPS (puerto `443`) en la VIP.
- Keepalived gestiona la VIP `10.207.154.20` mediante **unicast VRRP** (MASTER en `lb1` con prioridad 101, BACKUP en `lb2` con prioridad 100) y monitoriza el proceso de `haproxy`.

### Probar la Caída del Balanceador (Failover de VIP)

Para verificar el comportamiento de alta disponibilidad de la VIP, puedes ejecutar:
```bash
ansible-playbook 15_probar_caida_balanceador.yml
```
Este playbook:
1. Verifica que la VIP `10.207.154.20` la tiene asignada `lb1` inicialmente.
2. Lanza un script de curls continuas a la VIP (cada 100ms) en segundo plano.
3. Detiene instantáneamente el contenedor `lb1` (`lxc stop lb1 --force`).
4. Comprueba los códigos de estado HTTP y valida que la conmutación a `lb2` tardó un tiempo mínimo (generalmente < 0.5s, resultando en muy pocas peticiones fallidas).
5. Vuelve a arrancar `lb1` y verifica que reclama la VIP automáticamente por *preemption*.

### Monitorización del Cluster (Prometheus + Grafana)

Para monitorizar el cluster, puedes ejecutar:
```bash
ansible-playbook 16_instalar_monitorizacion.yml
```
Este playbook realiza:
1. **Configuración de Docker**: Desactiva `containerd-snapshotter` (forzando el uso de `overlay2`) en `/etc/docker/daemon.json` en los 5 nodos de Swarm para solucionar los problemas de resolución de nombres de contenedor de cAdvisor, y habilita las métricas experimentales en el puerto `9323`.
2. **Exposición en HAProxy**: Activa el exportador nativo de Prometheus en el puerto `8404` de los balanceadores.
3. **Prometheus & Grafana**: Levanta contenedores para Prometheus (puerto `9090`) y Grafana (puerto `3000`) en el nodo externo `portainer-server`.
4. **Dashboards Aprovisionados**: Se provisionan tres dashboards modernos e independientes:
   * **`Swarm Cluster & Nodes Overview`**: Estado global de salud, número de réplicas en ejecución y recursos agregados por servicios de Swarm.
   * **`Container Deep Dive & Troubleshooting`**: Zoom individual de recursos (CPU, RAM) por contenedor y host de destino mediante variables en cascada enlazadas sin puertos rígidos.
   * **`Node Exporter Host Overview`**: Monitorización pormenorizada del hardware físico de cada máquina.
5. **Acceso a Grafana**:
   * **Usuario**: `admin`
   * **Contraseña**: `mipass12345678`

> [!NOTE]
> Debido al aislamiento de seguridad de los contenedores LXD sin privilegios (*unprivileged*), los agentes de cAdvisor no pueden saltar el namespace de red ni el ptrace del kernel para leer estadísticas individuales de I/O de disco y Red de contenedores ajenos. Para resolver esto, los paneles globales muestran la actividad agregada mediante las métricas nativas y seguras de Node Exporter y los balanceadores.

### Centralización de Logs (Grafana Loki + Promtail)

Para agregar y visualizar los logs de todo el clúster, puedes ejecutar:
```bash
ansible-playbook 18_instalar_loki_logs.yml
```
Este playbook realiza:
1. **Loki Server**: Levanta un contenedor de Grafana Loki (puerto `3100`) de forma centralizada en el servidor `portainer-server`.
2. **Datasource de Loki**: Aprovisiona automáticamente el origen de datos Loki en Grafana.
3. **Agentes Promtail**: Copia y configura el agente Promtail como un servicio `systemd` en **todos los nodos del laboratorio**:
   * **Nodos Swarm**: Recopila los logs de salida estándar de los contenedores Docker (`/var/lib/docker/containers/*/*.log`).
   * **Balanceadores (`lb1`/`lb2`)**: Recopila los logs de HAProxy y eventos de Keepalived en `/var/log/syslog` y `/var/log/haproxy.log`.
   * **Servidor Portainer**: Recopila los logs de los contenedores de infraestructura (Prometheus, Grafana y Loki).

#### Búsqueda interactiva de Logs (LogQL)
Para consultar logs en tiempo real, entra en Grafana > **Explore** y selecciona **Loki** como origen de datos. Ejemplos de filtros:
* Logs de contenedores Docker: `{job="docker"}`
* Logs de un contenedor específico: `{job="docker", container_id="<id_contenedor>"}`
* Logs de HAProxy / Keepalived: `{job="syslog"}` o `{job="haproxy"}`
* Logs del servidor de monitorización: `{host="portainer-server"}`

### Generador de Tráfico de Carga (HTTP Load Testing)

Para simular tráfico real y poblar de datos de forma abundante las gráficas de HAProxy y Docker Swarm en Grafana, puedes iniciar el generador asíncrono:
```bash
ansible-playbook 17_generar_trafico.yml
```
Este playbook:
- Intenta utilizar `ab` (ApacheBench) localmente para enviar 500,000 peticiones concurrentes a la VIP.
- Si `ab` no está instalado, utiliza un bucle concurrente con `curl`.
- Se ejecuta **en segundo plano de forma asíncrona** durante 5 minutos para que puedas abrir el panel de Grafana y ver las curvas de conexiones, transferencia de bytes y volumen de respuestas de inmediato.
- Para detener el tráfico antes de que finalicen los 5 minutos, ejecuta: `killall ab` o `killall curl`.

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
ansible-playbook 28_desinstalar_agente_portainer.yml

# 2. Elimina Portainer Server y su volumen de datos
ansible-playbook 29_desinstalar_portainer.yml

# 3. Destruye los nodos LXD y limpia tokens
ansible-playbook 30_destroy.yml
```

O si prefieres destruir directamente los nodos LXD sin desinstalar Portainer previamente (por ejemplo, si no necesitas limpiar los volúmenes de Docker de forma ordenada):

```bash
ansible-playbook 30_destroy.yml
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
