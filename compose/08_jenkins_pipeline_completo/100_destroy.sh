#!/bin/bash
# Para y elimina los contenedores, y borra los directorios de volúmenes
set -e
cd "$(dirname "$0")"

# Para primero los despliegues que hayan podido quedar vivos de los
# ejemplos que despliegan de verdad (33, 50-53, 92): si no, sus
# contenedores siguen conectados a la red del stack y "docker compose
# down" no puede borrarla (avisa "Resource is still in use" y la deja
# huérfana).
for f in jenkinsfile/*/05_stop_deploy.sh; do
  [ -f "$f" ] && "$f" || true
done
# 52_deploy_multientorno puede tener desplegados los dos entornos a la vez
if [ -f jenkinsfile/52_deploy_multientorno/05_stop_deploy.sh ]; then
  jenkinsfile/52_deploy_multientorno/05_stop_deploy.sh produccion
fi

# Destruir también el nodo LXC de Docker externo si existe
if [ -f ./97_destroy_lxc_docker_node.sh ]; then
  ./97_destroy_lxc_docker_node.sh
fi

docker compose -p jenkins_docker_pipeline down -v
sudo rm -rf ./jenkins_home ./nexus_data ./config/ssh ./config/certs

echo "Todo destruido (contenedores, jenkins_home, nexus_data, config/ssh y config/certs). Para empezar de cero:"
echo "  ./00_init.sh && ./01_launch.sh"
