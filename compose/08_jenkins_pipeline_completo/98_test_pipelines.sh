#!/bin/bash
set -euo pipefail

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Encontrar los ejemplos ordenados por número
EXAMPLES=($(find jenkinsfile -mindepth 1 -maxdepth 1 -type d | sort | xargs -n1 basename))

is_running() {
  local container_name="$1"
  [ -n "$(docker ps --filter "name=^${container_name}$" --filter "status=running" -q 2>/dev/null)" ]
}

ensure_controller() {
  if ! is_running "jenkins_docker_pipeline"; then
    echo "==> Iniciando Jenkins Controller..."
    ./01_launch.sh
    echo "==> Esperando a que el Jenkins Controller responda..."
    for i in $(seq 1 30); do
      CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:admin" "http://localhost:8082/api/json" 2>/dev/null || echo "000")
      if [ "$CODE" = "200" ]; then
        echo "    [OK] Jenkins listo."
        return 0
      fi
      sleep 2
    done
    echo "ERROR: Jenkins no respondió tras iniciar." >&2
    exit 1
  fi
}

ensure_agent1() {
  ensure_controller
  if ! is_running "jenkins_docker_pipeline_agent"; then
    echo "==> Iniciando Agent 1 (agent1)..."
    ./04_launch_agent.sh
    ./05_check_agent.sh
  fi
}

ensure_agent2() {
  ensure_controller
  if ! is_running "jenkins_docker_pipeline_agent_docker"; then
    echo "==> Iniciando Agent 2 (agent2 con Docker)..."
    ./06_launch_agent_docker.sh
    ./07_check_agent_docker.sh
  fi
}

ensure_nexus() {
  ensure_controller
  if ! is_running "jenkins_docker_pipeline_nexus"; then
    echo "==> Iniciando Nexus..."
    ./08_launch_nexus.sh
  fi
  # Ejecutar siempre el setup para garantizar que las credenciales existan en Jenkins
  ./09_setup_nexus.sh
}

ensure_sonar() {
  ensure_controller
  if ! is_running "jenkins_docker_pipeline_sonar"; then
    echo "==> Iniciando SonarQube..."
    ./12_launch_sonar.sh
  fi
  # Ejecutar siempre el setup para garantizar que las credenciales existan en Jenkins
  ./13_setup_sonar.sh
}

ensure_external_docker() {
  # Ambos scripts son idempotentes. Se ejecutan siempre para cubrir también
  # estados parciales: LXC existente sin Docker, certificados renovados o un
  # Controller que aún conserva en memoria una CA anterior.
  echo "==> Preparando nube externa Docker en LXC..."
  ./10_create_lxc_docker_node.sh
  ./11_install_docker_lxc.sh

  # Si el Controller no existía, arranca después de crear los certificados
  # reales para que JCasC cargue docker-external-tls-creds correctamente.
  ensure_controller
}

run_pipeline() {
  local name="$1"
  local num_str="${name%%_*}"
  local num=$((10#$num_str))

  echo "======================================================================"
  echo ">>> PROBANDO PIPELINE: $name"
  echo "======================================================================"

  # Asegurar infraestructura requerida
  if [[ $num -ge 20 && $num -le 25 ]] || [[ $num -eq 27 ]]; then
    ensure_agent1
  elif [[ $num -eq 26 ]]; then
    ensure_agent2
  elif [[ $num -ge 30 && $num -le 33 ]] || [[ $num -eq 91 ]] || [[ $num -eq 92 ]]; then
    ensure_nexus
  elif [[ $num -eq 47 ]]; then
    ensure_sonar
  elif [[ $num -eq 61 ]]; then
    ensure_external_docker
  else
    ensure_controller
  fi

  # Para el ejemplo 91 y 92, es recomendable haber creado la credencial de gitlab en 90
  if [[ $num -eq 91 ]] || [[ $num -eq 92 ]]; then
    echo "==> Nota: Los ejemplos 91 y 92 requieren que el token de GitLab esté configurado (ejemplo 90)."
    echo "    Si falla, asegúrate de haber ejecutado previamente el ejemplo 90_gitlab_token_credential."
  fi

  # Ejecutar script de preparación (como credenciales de demo) si existe
  if [ -f "./jenkinsfile/$name/00_create_credentials.sh" ]; then
    echo "==> Ejecutando script de preparación preliminar (00_create_credentials.sh)..."
    if ! "./jenkinsfile/$name/00_create_credentials.sh"; then
      echo "==> [ERROR] Falló la preparación preliminar para '$name'."
      return 1
    fi
  fi

  # Entrar y ejecutar
  echo "==> Creando job en Jenkins..."
  if ! "./jenkinsfile/$name/01_create.sh"; then
    echo "==> [ERROR] Falló la creación del job '$name'."
    return 1
  fi

  echo "==> Lanzando ejecución y esperando resultado..."
  local build_failed=0
  if "./jenkinsfile/$name/02_build.sh"; then
    echo "==> [ÉXITO] Pipeline '$name' completada correctamente."
  else
    echo "==> [ERROR] La pipeline '$name' ha fallado."
    build_failed=1
  fi

  # Parar el despliegue si existe un script para detenerlo (serie 50, 33, 92)
  if [ -f "./jenkinsfile/$name/05_stop_deploy.sh" ]; then
    echo "==> Deteniendo despliegue de prueba (05_stop_deploy.sh)..."
    "./jenkinsfile/$name/05_stop_deploy.sh" || true
  fi

  echo "==> Eliminando el job..."
  "./jenkinsfile/$name/04_delete.sh" || true

  if [ $build_failed -eq 1 ]; then
    return 1
  fi

  echo ">>> [OK] Test de '$name' finalizado."
  return 0
}

show_menu() {
  echo "=========================================="
  echo "   Jenkins Pipeline Test Interactive Menu"
  echo "=========================================="
  for i in "${!EXAMPLES[@]}"; do
    printf "  [%2d] %s\n" $((i+1)) "${EXAMPLES[$i]}"
  done
  echo "------------------------------------------"
  echo "  [A] Ejecutar todos los ejemplos en orden"
  echo "  [Q] Salir"
  echo "=========================================="
  read -p "Selecciona una opción (1-${#EXAMPLES[@]}, A o Q): " OPTION
}

# Variables para resumir resultados
declare -A RESULTS

run_all_pipelines() {
  local failed_count=0
  local success_count=0

  for name in "${EXAMPLES[@]}"; do
    if run_pipeline "$name"; then
      RESULTS["$name"]="SUCCESS"
      success_count=$((success_count+1))
    else
      RESULTS["$name"]="FAILED"
      failed_count=$((failed_count+1))
    fi
  done

  echo ""
  echo "========================================================"
  echo "                  RESUMEN DE PRUEBAS"
  echo "========================================================"
  for name in "${EXAMPLES[@]}"; do
    printf "  %-40s : %s\n" "$name" "${RESULTS[$name]:-PENDING}"
  done
  echo "========================================================"
  echo " Total exitosos: $success_count"
  echo " Total fallados: $failed_count"
  echo " Total analizados: ${#EXAMPLES[@]}"
  echo "========================================================"
}

# Comprobar si se ha pasado un argumento directo
if [ $# -gt 0 ]; then
  ARG="$1"
  if [[ "$ARG" == "all" || "$ARG" == "A" ]]; then
    echo "Ejecutando TODOS los ejemplos..."
    run_all_pipelines
    exit 0
  else
    # Buscar por nombre exacto o número
    FOUND=""
    for name in "${EXAMPLES[@]}"; do
      if [[ "$name" == "$ARG" || "${name%%_*}" == "$ARG" ]]; then
        FOUND="$name"
        break
      fi
    done
    if [ -n "$FOUND" ]; then
      run_pipeline "$FOUND"
      exit 0
    else
      echo "Ejemplo '$ARG' no encontrado."
      exit 1
    fi
  fi
fi

# Modo interactivo
while true; do
  show_menu
  if [[ "$OPTION" =~ ^[qQ]$ ]]; then
    echo "Saliendo..."
    break
  elif [[ "$OPTION" =~ ^[aA]$ ]]; then
    echo "Iniciando ejecución de todas las pipelines..."
    run_all_pipelines
  elif [[ "$OPTION" =~ ^[0-9]+$ ]] && [ "$OPTION" -ge 1 ] && [ "$OPTION" -le "${#EXAMPLES[@]}" ]; then
    idx=$((OPTION-1))
    run_pipeline "${EXAMPLES[$idx]}" || true
  fi
  echo ""
  read -p "Pulsa Enter para volver al menú..."
done
