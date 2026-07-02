#!/usr/bin/env bash
# Instala Docker Engine en los 5 nodos siguiendo el procedimiento oficial
# (repositorio + GPG de Docker), el mismo que se enseña en la Unidad 00.
# Se lanza en paralelo (background + wait) porque son 5 "apt-get install"
# independientes: hacerlo en serie sería 5 veces más lento sin ganar nada.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source nodos.conf

# 'lxc exec <nodo> -- bash -s' ejecuta este bloque heredoc DENTRO del
# contenedor, como si fuera un script local — así no hace falta SSH.
install_docker() {
  local name="$1"
  lxc exec "$name" -- bash -s <<'EOF'
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
}

echo "==> Instalando Docker Engine en los 5 nodos (en paralelo)..."
pids=()
for name in "${NODE_NAMES[@]}"; do
  echo "    Lanzando instalación en $name..."
  install_docker "$name" &
  pids+=($!)
done

fail=0
for pid in "${pids[@]}"; do
  wait "$pid" || fail=1
done

if [ "$fail" -eq 1 ]; then
  echo "ERROR: la instalación de Docker falló en algún nodo" >&2
  exit 1
fi

echo "==> Docker instalado en todos los nodos:"
for name in "${NODE_NAMES[@]}"; do
  echo "    $name: $(lxc exec "$name" -- docker --version)"
done
