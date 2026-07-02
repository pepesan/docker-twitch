#!/usr/bin/env bash
# Instala Portainer para gestionar el cluster Swarm DESDE FUERA de él:
#
#   - Portainer SERVER se instala en un nodo aparte (portainer-server), que
#     no se une al Swarm. Así puedes seguir administrando el cluster aunque
#     algún manager esté caído, y separas "quién gestiona" de "quién ejecuta
#     la carga" — igual que se recomienda en producción.
#   - Portainer AGENT se despliega DENTRO del cluster como servicio Swarm en
#     modo global (--mode global): una réplica en cada uno de los 5 nodos,
#     managers y workers. El agente es quien de verdad habla con el socket
#     de Docker de cada nodo; Portainer Server solo habla con el agente por
#     red (puerto 9001), nunca monta el socket de un nodo remoto directamente.
#
# Referencia: https://docs.portainer.io/start/install-ce/server/swarm/docker
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

PORTAINER_NODE="portainer-server"
PORTAINER_IP="10.207.154.15"
PORTAINER_CPU="1"
PORTAINER_MEM="2GB"
PORTAINER_DISK="20GB"
MANAGER1="${NODE_NAMES[0]}"
MANAGER1_IP="${NODE_IPS[0]}"

# 1) Crear el nodo de Portainer, fuera del cluster Swarm ---------------------
if ! lxc info "$PORTAINER_NODE" &>/dev/null; then
  echo "==> Creando $PORTAINER_NODE (IP $PORTAINER_IP) — no se unirá al Swarm"
  lxc init "$IMAGE" "$PORTAINER_NODE"
  lxc config set "$PORTAINER_NODE" limits.cpu="$PORTAINER_CPU"
  lxc config set "$PORTAINER_NODE" limits.memory="$PORTAINER_MEM"
  lxc config device override "$PORTAINER_NODE" root size="$PORTAINER_DISK"
  lxc config device override "$PORTAINER_NODE" eth0 ipv4.address="$PORTAINER_IP"
  # Mismos requisitos especiales que el resto de nodos (ver 01_crear_nodos.sh):
  # solo hace falta Docker "normal" aquí, pero se dejan por si algún día este
  # nodo también participa en algo con overlay/routing mesh.
  lxc config set "$PORTAINER_NODE" security.nesting=true
  lxc config set "$PORTAINER_NODE" security.privileged=true
  lxc config set "$PORTAINER_NODE" linux.kernel_modules="$KERNEL_MODULES"
  lxc start "$PORTAINER_NODE"

  echo "==> Esperando a que $PORTAINER_NODE responda..."
  for attempt in $(seq 1 30); do
    lxc exec "$PORTAINER_NODE" -- true &>/dev/null && break
    sleep 2
  done
else
  echo "==> $PORTAINER_NODE ya existe, se omite la creación"
fi

# 2) Instalar Docker en el nodo de Portainer (mismo procedimiento que el resto)
if ! lxc exec "$PORTAINER_NODE" -- command -v docker &>/dev/null; then
  echo "==> Instalando Docker en $PORTAINER_NODE"
  lxc exec "$PORTAINER_NODE" -- bash -s <<'EOF'
set -euo pipefail
apt-get update -qq
apt-get install -y -qq ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker.service containerd.service
EOF
else
  echo "==> Docker ya estaba instalado en $PORTAINER_NODE"
fi

# 3) Arrancar Portainer Server como contenedor suelto (NO es un servicio Swarm:
#    este nodo no pertenece al cluster) ---------------------------------------
echo "==> Arrancando Portainer Server"
lxc exec "$PORTAINER_NODE" -- docker volume create portainer_data >/dev/null
lxc exec "$PORTAINER_NODE" -- docker rm -f portainer &>/dev/null || true
lxc exec "$PORTAINER_NODE" -- docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:2.41.1

# 4) Desplegar el Agent DENTRO del cluster, en modo global --------------------
echo "==> Creando la red overlay del agente (si no existe)"
lxc exec "$MANAGER1" -- docker network create \
  --driver overlay \
  --attachable \
  portainer_agent_net &>/dev/null || echo "    (la red portainer_agent_net ya existía)"

echo "==> Desplegando el Portainer Agent en el cluster (modo global, un agente por nodo)"
lxc exec "$MANAGER1" -- docker service create \
  --name portainer_agent \
  --mode global \
  --network portainer_agent_net \
  --publish mode=host,target=9001,published=9001 \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=bind,src=/var/lib/docker/volumes,dst=/var/lib/docker/volumes \
  portainer/agent:2.41.1 \
  >/dev/null || echo "    (el servicio portainer_agent ya existía, se mantiene)"

echo ""
echo "==> Listo:"
echo "    Portainer Server: https://$PORTAINER_IP:9443  (fuera del cluster)"
echo "    Portainer Agent:  desplegado en los 5 nodos, puerto 9001"
echo ""
echo "    Al configurar el entorno en Portainer: Environments -> Add environment"
echo "    -> Docker Swarm -> Agent, con dirección tcp://$MANAGER1_IP:9001"
echo "    (vale la IP de cualquier nodo del cluster, no tiene que ser un manager)"
