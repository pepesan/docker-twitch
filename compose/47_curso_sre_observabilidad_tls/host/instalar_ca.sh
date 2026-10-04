#!/usr/bin/env bash
# ⚠ Instala la CA raíz del laboratorio (pki/root.crt) como de confianza en ESTA
# máquina: almacén del sistema (usa sudo) y bases NSS de Chrome/Chromium y
# Firefox. Lo ejecutas tú; ningún otro script del laboratorio lo llama.
#
#   ./host/instalar_ca.sh            -> instala (sustituye la anterior, si había)
#   ./host/instalar_ca.sh --quitar   -> la retira
# Es idempotente. Cada `20_destroy.sh` + `00_init.sh` genera una CA nueva:
# vuelve a ejecutarlo para sustituir la vieja.
#
# Para las bases NSS hace falta `certutil` (Debian/Ubuntu: libnss3-tools;
# Fedora: nss-tools). Sin él solo se instala en el sistema; Firefox también
# puede usar el del sistema activando security.enterprise_roots.enabled.
set -euo pipefail

cd "$(dirname "$0")/.."
CRT="pki/root.crt"
NICK="Curso SRE Lab Root CA"
ARCHIVO="curso-sre-lab.crt"
DRY_RUN="${DRY_RUN:-0}"                    # 1 = solo muestra lo que haría
SALTAR_SISTEMA="${SALTAR_SISTEMA:-0}"      # 1 = solo navegadores (no toca el sistema)
quitar=0; [ "${1:-}" = "--quitar" ] && quitar=1

run() { if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

if [ "$quitar" = 0 ] && [ ! -f "$CRT" ]; then
    echo "No existe $CRT: ejecuta antes ./00_init.sh" >&2; exit 1
fi

# --- 1. almacén del sistema -------------------------------------------------
echo "== Almacén del sistema"
if [ "$SALTAR_SISTEMA" = 1 ]; then
    echo "  (saltado por SALTAR_SISTEMA=1)"
elif command -v update-ca-certificates >/dev/null; then          # Debian/Ubuntu
    dest="/usr/local/share/ca-certificates/$ARCHIVO"
    if [ "$quitar" = 1 ]; then run sudo rm -f "$dest"; else run sudo cp "$CRT" "$dest"; fi
    run sudo update-ca-certificates $([ "$quitar" = 1 ] && echo --fresh)
elif command -v update-ca-trust >/dev/null; then               # Fedora/RHEL
    dest="/etc/pki/ca-trust/source/anchors/$ARCHIVO"
    if [ "$quitar" = 1 ]; then run sudo rm -f "$dest"; else run sudo cp "$CRT" "$dest"; fi
    run sudo update-ca-trust
else
    echo "  No se encontró update-ca-certificates ni update-ca-trust: sistema no soportado, salto este paso."
fi

# --- 2. bases NSS (Chrome/Chromium y perfiles de Firefox) --------------------
echo "== Navegadores (NSS)"
if ! command -v certutil >/dev/null; then
    echo "  Falta certutil (libnss3-tools / nss-tools): no se toca ningún navegador."
    echo "  Alternativa: importa $CRT a mano en el navegador (README, «Confiar en la CA local»)."
    exit 0
fi

dbs=()
# Chrome/Chromium usan ~/.pki/nssdb (se crea vacía si no existe y estamos instalando)
if [ "$quitar" = 0 ] && [ ! -d "$HOME/.pki/nssdb" ]; then
    run mkdir -p "$HOME/.pki/nssdb"
    run certutil -N --empty-password -d "sql:$HOME/.pki/nssdb"
fi
[ -d "$HOME/.pki/nssdb" ] && dbs+=("$HOME/.pki/nssdb")
# Firefox: perfiles normales, snap y flatpak
for f in "$HOME"/.mozilla/firefox/*/cert9.db \
         "$HOME"/snap/firefox/common/.mozilla/firefox/*/cert9.db \
         "$HOME"/.var/app/org.mozilla.firefox/.mozilla/firefox/*/cert9.db; do
    [ -f "$f" ] && dbs+=("$(dirname "$f")")
done

if [ "${#dbs[@]}" = 0 ]; then echo "  No hay bases NSS que tocar."; exit 0; fi
for db in "${dbs[@]}"; do
    echo "  $db"
    # borra la anterior con el mismo nombre (puede no existir)
    if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] certutil -D -n '$NICK' -d sql:$db"
    else certutil -D -n "$NICK" -d "sql:$db" 2>/dev/null || true; fi
    [ "$quitar" = 1 ] || run certutil -A -n "$NICK" -t "C,," -i "$CRT" -d "sql:$db"
done
echo "Hecho. Reinicia el navegador si estaba abierto."
