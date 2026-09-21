#!/usr/bin/env bash
# Crea las carpetas de datos persistentes en ./data y genera credenciales
# nuevas (postgres, S3, HAProxy) a partir de las plantillas *.template —
# los ficheros reales generados NO están en git (ver .gitignore). Ejecutar
# una vez antes del primer 01_launch_compose.sh y cada vez que se borre
# con 20_destroy.sh.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p \
  data/master1 data/master2 data/master3 \
  data/volume1 data/volume2 data/volume3 \
  data/postgres

if [ -f .env ]; then
    echo "Ya existen credenciales generadas (.env), no se regeneran."
    echo "Borra .env, filer-config/filer.toml, s3-config/s3.json y haproxy/haproxy.cfg si quieres unas nuevas."
    exit 0
fi

postgres_password=$(openssl rand -hex 16)
s3_access_key=$(openssl rand -hex 10)
s3_secret_key=$(openssl rand -hex 20)
filer_ui_password=$(openssl rand -base64 12 | tr -d '=+/')
filer_ui_hash=$(openssl passwd -6 "${filer_ui_password}")
stats_password=$(openssl rand -base64 12 | tr -d '=+/')

echo "POSTGRES_PASSWORD=${postgres_password}" > .env

python3 - "$postgres_password" "$s3_access_key" "$s3_secret_key" "$filer_ui_hash" "$stats_password" << 'EOF'
import sys
pg_pw, s3_ak, s3_sk, filer_hash, stats_pw = sys.argv[1:6]

def render(template_path, output_path, replacements):
    text = open(template_path).read()
    for placeholder, value in replacements.items():
        text = text.replace(placeholder, value)
    open(output_path, "w").write(text)

render("filer-config/filer.toml.template", "filer-config/filer.toml",
       {"__POSTGRES_PASSWORD__": pg_pw})
render("s3-config/s3.json.template", "s3-config/s3.json",
       {"__S3_ACCESS_KEY__": s3_ak, "__S3_SECRET_KEY__": s3_sk})
render("haproxy/haproxy.cfg.template", "haproxy/haproxy.cfg",
       {"__FILER_UI_PASSWORD_HASH__": filer_hash, "__STATS_PASSWORD__": stats_pw})
EOF

echo "Credenciales generadas:"
echo "  postgres:   seaweedfs / ${postgres_password}"
echo "  S3:         accessKey=${s3_access_key} secretKey=${s3_secret_key}"
echo "  Filer UI:   pepesan / ${filer_ui_password}"
echo "  HAProxy UI: pepesan / ${stats_password}  (http://localhost:1936)"
echo "Guárdalas ahora — la contraseña de Filer UI y la de stats no se pueden recuperar después (solo su hash queda en haproxy/haproxy.cfg)."
