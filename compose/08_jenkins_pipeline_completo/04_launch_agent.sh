#!/bin/bash
# Genera (si hace falta) la clave SSH del agente y levanta el servicio
# jenkins_agent (perfil "agent" de compose.yaml), junto al controller
set -e
cd "$(dirname "$0")"

if [ ! -f ./config/ssh/id_ed25519 ]; then
  mkdir -p ./config/ssh
  ssh-keygen -t ed25519 -N "" -C "jenkins-agent" -f ./config/ssh/id_ed25519
fi

export AGENT_SSH_PUBLIC_KEY="$(cat ./config/ssh/id_ed25519.pub)"
docker compose -p jenkins_docker_pipeline --profile agent up -d --build

echo
echo "Agente arrancando. La conexión SSH al controller puede tardar unos"
echo "segundos (varios reintentos automáticos)."
echo "Comprueba que ha quedado registrado y online con ./05_check_agent.sh"
