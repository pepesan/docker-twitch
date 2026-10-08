# Cargado con "source" desde el resto de scripts (nunca se ejecuta solo).
# Exporta las variables de .env (config no sensible, versionada) y de
# secrets.env (contraseñas generadas, gitignorado) para que tanto
# "docker compose" como los comandos sueltos de este directorio las vean.
set -a
source "${AWX_EXAMPLE_DIR}/.env"
if [ -f "${AWX_EXAMPLE_DIR}/secrets.env" ]; then
    source "${AWX_EXAMPLE_DIR}/secrets.env"
else
    echo "Aviso: no existe secrets.env todavía. Ejecuta primero ./00_init.sh" >&2
fi
set +a
