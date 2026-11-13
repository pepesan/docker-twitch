#!/usr/bin/env bash
# Levanta el laboratorio de principio a fin y deja listos los recursos de
# ejemplo (usuario, credencial, proyecto, inventario y plantillas). No ejecuta
# ninguna plantilla sobre el destino: para eso están 18-25 y 90_e2e.sh.
#
# Usa los scripts 00, 01, 02 y 08 de este mismo laboratorio.
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f e2e.env ]]; then
    echo 'Falta e2e.env: copia e2e.env.example a e2e.env y revisa los valores.' >&2
    exit 1
fi
LAB_DIR="$PWD"
HERE="$PWD"

lab() { ( cd "$LAB_DIR" && "$@" ); }

admin_exists() {
    ( cd "$LAB_DIR" && docker compose exec -T awx awx-manage shell -c \
        "import sys; from django.contrib.auth.models import User; sys.exit(0 if User.objects.filter(username='admin').exists() else 1)" ) >/dev/null 2>&1
}

ui_built() {
    ( cd "$LAB_DIR" && docker compose exec -T awx test -f /awx_devel/awx/ui/.ui-built ) >/dev/null 2>&1
}

if ! ( cd "$LAB_DIR" && docker compose ps --status running --services 2>/dev/null | grep -qx awx ); then
    echo '== 00_init.sh y 01_launch_compose.sh'
    lab ./00_init.sh
    lab ./01_launch_compose.sh
fi

echo '== Esperando migraciones y usuario admin'
for _ in $(seq 1 120); do admin_exists && break; sleep 10; done
admin_exists || { echo 'El usuario admin no existe tras 20 minutos.' >&2; exit 1; }

echo '== 02_create_admin.sh'
lab ./02_create_admin.sh >/dev/null 2>&1 || { echo '02_create_admin.sh falló; ejecútalo a mano para ver el error.' >&2; exit 1; }

if ! ui_built; then
    echo '== 08_build_ui.sh (la primera vez tarda varios minutos)'
    lab ./08_build_ui.sh
fi

source "$HERE/scripts/lib_awx_e2e.sh"
echo '== Esperando a que la API responda'
for _ in $(seq 1 90); do api_admin_login 2>/dev/null && break; sleep 5; done
api_admin_login

for step in 10_create_user 11_create_organization 12_add_user_to_organization 13_create_credential \
    14_create_project 15_create_inventory 16_create_templates 17_check_e2e_resources; do
    echo "== $step"
    "$HERE/$step.sh"
done
echo "AWX listo en $AWX_URL con los recursos de ejemplo."
