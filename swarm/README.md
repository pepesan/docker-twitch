# Laboratorio: cluster Docker Swarm sobre LXD

Crea un cluster Docker Swarm real de 5 nodos (3 managers + 2 workers) usando
contenedores LXD como si fueran máquinas independientes. Escenario y recursos
alineados con la unidad "Docker Swarm" del curso (`docker-portainer-swarm_06.yaml`).

## Requisitos previos

- LXD instalado y funcionando (`lxc list` debe responder).
- Imagen local `ubuntu-2404-ssh-template` disponible (`lxc image list`), con
  tu clave pública ya añadida a `/root/.ssh/authorized_keys` — permite
  `ssh root@<ip>` a cualquier nodo sin configuración adicional.
- Red gestionada `lxdbr0` (`lxc network list`), en el rango `10.207.154.0/24`.

Todo esto se comprueba automáticamente en el paso `00`.

### Requisitos especiales de LXD para Docker Swarm (aplicados por `01`)

Docker (y sobre todo Swarm) dentro de un contenedor LXD **no funciona con la
configuración por defecto**. Esto se descubrió probando el laboratorio de
verdad, no es teoría — sin estos tres ajustes falla de tres formas distintas:

| Ajuste LXD | Sin él, falla así |
|---|---|
| `security.nesting=true` | Cualquier `docker run`/`service create` falla con `open sysctl net.ipv4.ip_unprivileged_port_start: permission denied` |
| `linux.kernel_modules=ip_vs,ip_vs_rr,...` | Declara los módulos que dockerd necesita (routing mesh, overlay, NAT) |
| `security.privileged=true` | El routing mesh falla al crear la red `ingress`: `open /proc/sys/net/ipv4/vs/conntrack: no such file or directory`. Sin esto, `docker service create --publish` con varias réplicas nunca converge |

`01_crear_nodos.sh` ya aplica los tres automáticamente a cada nodo — esta
tabla es para cuando lo repliques en otra máquina o reconstruyas un nodo a mano.

### Crear la imagen `ubuntu-2404-ssh-template` (si no la tienes)

Si en tu máquina no existe todavía esta imagen local, se crea así: se lanza
un Ubuntu 24.04 normal, se le mete tu clave pública en `authorized_keys` de
`root`, y se "publica" el contenedor resultante como una imagen local nueva
reutilizable con `lxc launch`.

```bash
# 1. Lanzar un Ubuntu 24.04 base desde el catálogo remoto de imágenes
lxc launch ubuntu:24.04 base-ssh-builder
sleep 10   # esperar a que arranque y tenga red

# 2. Añadir tu clave pública a authorized_keys de root
lxc exec base-ssh-builder -- mkdir -p /root/.ssh
lxc file push ~/.ssh/id_ed25519.pub base-ssh-builder/root/.ssh/authorized_keys
lxc exec base-ssh-builder -- chmod 700 /root/.ssh
lxc exec base-ssh-builder -- chmod 600 /root/.ssh/authorized_keys

# 3. (Opcional) Actualizar paquetes para que la imagen no arranque desactualizada
lxc exec base-ssh-builder -- apt-get update
lxc exec base-ssh-builder -- apt-get upgrade -y

# 4. Parar el contenedor y publicarlo como imagen local
lxc stop base-ssh-builder
lxc publish base-ssh-builder --alias ubuntu-2404-ssh-template

# 5. Limpiar el contenedor usado para construir la imagen (ya no hace falta)
lxc delete base-ssh-builder

# 6. Comprobar que la imagen quedó disponible
lxc image list
```

Cambia `~/.ssh/id_ed25519.pub` por la ruta de tu clave pública real
(`~/.ssh/id_rsa.pub` si usas RSA). Cualquier contenedor lanzado después con
`lxc launch ubuntu-2404-ssh-template <nombre>` ya tendrá esa clave lista,
sin volver a configurarla — así es como funcionan `01_crear_nodos.sh` y el
resto de ejemplos del repo que usan esta plantilla.

## Nodos del laboratorio

| Host | Rol | IP | vCPU | RAM | Disco |
|------|-----|-----|------|-----|-------|
| manager1 | Manager (líder inicial) | 10.207.154.10 | 2 | 4 GB | 40 GB |
| manager2 | Manager | 10.207.154.11 | 2 | 4 GB | 40 GB |
| manager3 | Manager | 10.207.154.12 | 2 | 4 GB | 40 GB |
| worker1 | Worker | 10.207.154.13 | 4 | 8 GB | 80 GB |
| worker2 | Worker | 10.207.154.14 | 4 | 8 GB | 80 GB |

Todo se define en `nodos.conf`; los scripts leen ese fichero, no llevan
nombres/IPs hardcodeados.

## Uso: ejecutar en orden

```bash
./00_check_requisitos.sh    # Verifica LXD, imagen y red
./01_crear_nodos.sh         # Crea los 5 contenedores LXD con CPU/RAM/disco/IP fija
./02_instalar_docker.sh     # Instala Docker Engine en los 5 (en paralelo)
./03_swarm_init.sh          # docker swarm init en manager1; guarda los tokens
./04_swarm_join_managers.sh # Une manager2 y manager3 como managers
./05_swarm_join_workers.sh  # Une worker1 y worker2 como workers
./06_verificar_cluster.sh   # docker node ls — confirma los 5 nodos Ready
./07_desplegar_servicio.sh  # Despliega web-demo (nginx, 3 réplicas, solo en workers) y prueba el routing mesh
./08_probar_caida_nodo.sh   # Derriba un nodo y observa cómo se reprograma su tarea en otro
./09_instalar_portainer.sh  # Portainer Server (fuera del cluster) + Agent (dentro, modo global)
```

Al terminar, el cluster está operativo. Para entrar a un nodo:

```bash
lxc exec manager1 -- bash          # shell dentro del contenedor
ssh root@10.207.154.10             # o por SSH, con tu clave ya autorizada
```

## Probar la caída de un nodo (07 + 08)

`07_desplegar_servicio.sh` despliega `web-demo` (nginx, 3 réplicas, publicado
en `:8080`) con `--constraint node.role==worker` — los managers quedan libres
para el quórum Raft, no ejecutan carga de aplicación. El script valida
explícitamente que ninguna réplica cayó en un manager antes de seguir, y
comprueba que el servicio responde desde los 5 nodos gracias al routing mesh
(managers incluidos, aunque ninguno ejecute una réplica).

`08_probar_caida_nodo.sh [nombre-nodo]` reproduce en vivo el diagrama "qué
ocurre si cae un nodo" de `_06.yaml`:

1. Muestra en qué nodo está cada réplica de `web-demo`.
2. Para el contenedor LXD del nodo indicado (`worker2` por defecto) con
   `lxc stop`, simulando un apagón real — no es lo mismo que
   `docker node update --availability drain`, que sería una salida ordenada.
3. Espera a que Swarm detecte el fallo por heartbeat y reprograme la tarea
   perdida en un nodo `Ready`.
4. Muestra `docker node ls` y `docker service ps web-demo` para comprobar el
   resultado.
5. Levanta de nuevo el nodo (`lxc start`) y confirma que vuelve a `Ready`.

Para probar la caída de un **manager** y ver el comportamiento del quórum Raft:

```bash
./08_probar_caida_nodo.sh manager1
# Con manager1 caído, manager2 o manager3 asumen el liderazgo (2/3 = quórum)
lxc exec manager2 -- docker node ls
```

## Gestionar el cluster desde fuera con Portainer (09)

`09_instalar_portainer.sh` instala Portainer siguiendo el patrón recomendado
para Swarm: **Server fuera del cluster, Agent dentro**.

- Crea un 6º nodo LXD, `portainer-server` (10.207.154.15), que **no** se une
  al Swarm — así se puede seguir gestionando el cluster aunque algún manager
  esté caído.
- En ese nodo arranca `portainer/portainer-ce:2.41.1` como contenedor suelto
  (no un servicio Swarm).
- Dentro del cluster despliega `portainer/agent:2.41.1` como servicio Swarm
  en `--mode global` (una réplica en cada uno de los 5 nodos, managers
  incluidos — el agente es infraestructura de gestión, no carga de
  aplicación, por eso no lleva el `--constraint node.role==worker` de `07`).

```bash
./09_instalar_portainer.sh
```

Al terminar:

1. Abre `https://10.207.154.15:9443` y completa el alta del usuario admin.
2. **Environments → Add environment → Docker Swarm → Agent**.
3. Dirección del agente: `tcp://10.207.154.10:9001` (vale la IP de cualquier
   nodo del cluster, no tiene que ser manager1 — el agente resuelve solo
   quién es el líder actual).

## Destruir el laboratorio

```bash
./10_destroy.sh
```

Pide confirmación explícita (`si`) antes de borrar los 5 contenedores LXD del
cluster, el nodo `portainer-server` (si existe) y los ficheros `*.token`.

## Notas

- Las IPs (`10.207.154.10-14`) son del rango real de `lxdbr0` en esta máquina,
  distintas de las `192.168.1.x` usadas como ejemplo genérico en las
  diapositivas — el escenario (roles, recursos, topología) es el mismo.
- `02_instalar_docker.sh` instala los mismos paquetes y sigue los mismos pasos
  que se enseñan en la Unidad 00 del curso (repositorio oficial de Docker,
  `docker-ce docker-ce-cli containerd.io docker-compose-plugin`).
- Los tokens de unión (`manager.token`, `worker.token`) se guardan en esta
  carpeta y están en `.gitignore` — no se suben al repositorio.
