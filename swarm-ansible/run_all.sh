#!/usr/bin/env bash
# Ejecuta todos los playbooks del laboratorio en orden, uno detrás de otro.
# Antes de cada uno imprime una línea explicando qué hace, para poder seguir
# la ejecución sin tener que abrir cada fichero .yml.
#
# Uso: ./run_all.sh            (despliega el laboratorio completo)
#      ./run_all.sh --hasta 06 (para después de verificar el cluster,
#                                sin desplegar el servicio de prueba)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

HASTA="18"
if [ "${1:-}" = "--hasta" ]; then
  HASTA="$2"
fi

run_playbook() {
  local numero="$1"
  local fichero="$2"
  local descripcion="$3"

  if (( 10#$numero > 10#$HASTA )); then
    return
  fi

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  [$numero] $descripcion"
  echo "════════════════════════════════════════════════════════════════"
  ansible-playbook "$fichero"
}

run_playbook 00 00_instalar_lxd.yml         "Instalar LXD con ZFS en local (idempotente)"
run_playbook 01 01_crear_imagen_base.yml    "Crear la plantilla de imagen base ubuntu-2404-ssh-template"
run_playbook 02 02_check_requisitos.yml     "Comprobar LXD, la imagen base y la red antes de crear nada"
run_playbook 03 03_crear_nodos.yml          "Crear los 8 contenedores LXD (Swarm, Portainer y 2 balanceadores) con IP fija y recursos"
run_playbook 04 04_instalar_docker.yml      "Instalar Docker Engine en los 6 nodos"
run_playbook 05 05_swarm_init.yml           "Inicializar el cluster Swarm en manager1 y guardar los tokens de unión"
run_playbook 06 06_swarm_join_managers.yml  "Unir manager2 y manager3 como managers (quórum Raft de 3)"
run_playbook 07 07_swarm_join_workers.yml   "Unir worker1 y worker2 como workers"
run_playbook 08 08_verificar_cluster.yml    "Verificar que los 5 nodos del cluster están Ready"
run_playbook 09 09_desplegar_servicio.yml   "Desplegar un servicio web Python de prueba solo en workers y probar el routing mesh"
run_playbook 10 10_probar_caida_nodo.yml    "Simular la caída de un nodo y verificar la reprogramación automática en Swarm"
run_playbook 11 11_recuperar_cluster.yml    "Recuperar y reequilibrar el cluster Swarm después de la caída"
run_playbook 12 12_instalar_portainer.yml   "Instalar Portainer Server (fuera del cluster Swarm)"
run_playbook 13 13_instalar_agente_portainer.yml "Instalar Portainer Agent y registrar el cluster Swarm en Portainer"
run_playbook 14 14_instalar_haproxy_keepalived.yml "Instalar y configurar HAProxy + Keepalived con VIP active-passive"
run_playbook 15 15_probar_caida_balanceador.yml "Simular la caída del balanceador lb1 y verificar conmutación automática de la VIP"
run_playbook 16 16_instalar_monitorizacion.yml "Desplegar pila de monitorización Prometheus + Grafana y configurar exportación de métricas"
run_playbook 17 17_generar_trafico.yml "Generar tráfico HTTP asíncrono contra la VIP para poblar las métricas"
run_playbook 18 18_instalar_loki_logs.yml "Desplegar Loki y Promtail para centralizar logs"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Laboratorio desplegado. Para destruirlo: ./destroy_all.sh"
echo "════════════════════════════════════════════════════════════════"
