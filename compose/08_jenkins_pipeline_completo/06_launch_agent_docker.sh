#!/bin/bash
# Opcional. Genera (si hace falta) la clave SSH del SEGUNDO agente y lo
# levanta (perfil "agent-docker" de compose.yaml). A diferencia del agente
# SSH "puro" (04_launch_agent.sh), este tiene Docker CLI + el socket del
# host montado, para tareas que necesiten imágenes Docker de verdad.
set -e
cd "$(dirname "$0")"

if [ ! -f ./config/ssh/id_ed25519_agent2 ]; then
  mkdir -p ./config/ssh
  ssh-keygen -t ed25519 -N "" -C "jenkins-agent2" -f ./config/ssh/id_ed25519_agent2
fi

export AGENT2_SSH_PUBLIC_KEY="$(cat ./config/ssh/id_ed25519_agent2.pub)"
docker compose -p jenkins_docker_pipeline --profile agent-docker up -d --build

sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

echo
echo "Agente 'agent2' (con Docker) arrancando. La conexión SSH puede tardar"
echo "unos segundos (varios reintentos automáticos)."
echo "Comprueba que ha quedado registrado y online con ./07_check_agent_docker.sh"
