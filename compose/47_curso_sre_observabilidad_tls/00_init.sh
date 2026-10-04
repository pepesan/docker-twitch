#!/usr/bin/env bash
# Crea las carpetas de datos persistentes y genera compose.env con una
# contraseña de Grafana nueva (a partir de compose.env.template) si no existe
# todavía. Ejecutar una vez antes del primer 01_launch_metricas.sh (o 07_launch_todo.sh) y cada vez
# que se borre con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p volumes/prometheus/data volumes/alertmanager/data volumes/loki/data volumes/alloy/data volumes/tempo/data volumes/grafana/data volumes/caddy/data volumes/caddy/config
# Prometheus, Grafana, Loki y Tempo corren dentro del contenedor con un UID
# no-root distinto cada uno; en vez de averiguar y encajar cada UID, se abre
# el directorio para que cualquiera pueda escribir (aceptable en un
# laboratorio local, no en un despliegue real del CPD).
# Caddy corre como root y gestiona su propio directorio, así que se deja fuera;
# en una re-ejecución con el stack ya creado algunos ficheros son de otro
# usuario y chmod no puede tocarlos (no es un error: ya tienen permisos).
chmod -R 777 volumes/prometheus volumes/alertmanager volumes/loki volumes/alloy volumes/tempo volumes/grafana 2>/dev/null || true

if [ -f compose.env ]; then
    echo "compose.env ya existe, no se regenera (borra el fichero si quieres una password nueva)."
else
    admin_password=$(openssl rand -hex 12)
    sed -e "s/__GRAFANA_ADMIN_PASSWORD__/${admin_password}/" \
        compose.env.template > compose.env
    echo "compose.env generado. Credenciales iniciales de Grafana:"
    echo "  usuario:  admin"
    echo "  password: ${admin_password}"
fi

# Credenciales de acceso (basic_auth de Caddy) para todo salvo Grafana, que
# tiene su propio login. Van en un fichero aparte (caddy.env) para que no
# entren en el entorno del contenedor de Grafana (que carga compose.env
# entero). El hash bcrypt lleva `$`: se guarda entre comillas simples para que
# Compose no lo interprete como variable.
if [ -f caddy.env ]; then
    echo "caddy.env ya existe, no se regenera (borra el fichero si quieres una password nueva)."
else
    curso_password=$(openssl rand -hex 12)
    curso_hash=$(docker run --rm caddy:2.11.4 caddy hash-password --plaintext "${curso_password}")
    {
        echo "# Contraseña en claro (solo local, fichero excluido de Git): ${curso_password}"
        echo "CADDY_BASIC_USER=curso"
        echo "CADDY_BASIC_HASH='${curso_hash}'"
    } > caddy.env
    echo "caddy.env generado. Credenciales de Prometheus/Alertmanager/Loki/Tempo/hot-rod (vía Caddy):"
    echo "  usuario:  curso"
    echo "  password: ${curso_password}"
fi

# CA raíz del laboratorio, propia y persistente. Caddy la usa para firmar los
# certificados de los vhosts (genera él la intermedia). Vive en ./pki y la
# borra 20_destroy.sh con el resto del entorno. Se genera nosotros (en vez de
# dejar que Caddy improvise una) para poder tener el fichero listo antes de
# arrancar y no depender de `docker cp`. La clave privada no debe salir de
# esta máquina ni subirse a git (pki/ está en .gitignore).
if [ -f pki/root.crt ] && [ -f pki/root.key ]; then
    echo "pki/root.crt ya existe, no se regenera (borra ./pki para generar una nueva)."
else
    mkdir -p pki
    openssl ecparam -name prime256v1 -genkey -noout -out pki/root.key
    openssl req -x509 -new -key pki/root.key -sha256 -days 3650 \
        -subj "/O=Curso SRE Lab/CN=Curso SRE Lab Root CA" \
        -addext "basicConstraints=critical,CA:TRUE,pathlen:1" \
        -addext "keyUsage=critical,keyCertSign,cRLSign" \
        -out pki/root.crt
    # Caddy corre como root dentro del contenedor, pero el bind mount es de solo lectura
    chmod 644 pki/root.crt pki/root.key
    echo "CA raíz generada: pki/root.crt (importa este fichero en tu navegador/sistema, ver README)."
fi
