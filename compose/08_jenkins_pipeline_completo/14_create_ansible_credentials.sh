#!/usr/bin/env bash
# Paso 14: verifica el acceso SSH al destino y crea las credenciales Jenkins de Ansible.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

JENKINS_URL="${JENKINS_URL:-http://localhost:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-admin}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-admin}"
DEFAULT_LXC_IP="10.207.154.161"
LXC_IP="${ANSIBLE_LXC_IP:-$DEFAULT_LXC_IP}"
SSH_BOOTSTRAP_USER="${ANSIBLE_SSH_BOOTSTRAP_USER:-}"
SSH_DIR="$ROOT_DIR/config/ssh"
IP_CREDENTIAL_ID="ansible-lxc-ip"
AUTH="$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD"

credential_exists() {
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' -u "$AUTH" \
    "$JENKINS_URL/credentials/store/system/domain/_/credential/$1/api/json")"
  [[ "$code" == 200 ]]
}

command -v ssh >/dev/null || { echo "ERROR: instala openssh-client para comprobar el acceso SSH." >&2; exit 1; }
command -v ssh-keygen >/dev/null || { echo "ERROR: instala openssh-client para generar las claves." >&2; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: se necesita python3." >&2; exit 1; }

SSH_OPTIONS=(-o ConnectTimeout=5 -o ConnectionAttempts=1)
if [[ ! -t 0 ]]; then
  SSH_OPTIONS+=(-o BatchMode=yes)
fi
SSH_IDENTITY_OPTIONS=()
if [[ -f "$SSH_DIR/ansible_lxc_root" ]]; then
  SSH_IDENTITY_OPTIONS+=(-i "$SSH_DIR/ansible_lxc_root")
fi

ssh_probe() {
  local user="$1" ip="$2"
  ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$user" "$ip" true \
    >/dev/null
}

if ssh_probe root "$LXC_IP"; then
  SSH_BOOTSTRAP_USER=root
  echo "SSH root@$LXC_IP responde."
else
  echo "AVISO: no se pudo conectar por SSH como root a $LXC_IP."
  if [[ -z "$SSH_BOOTSTRAP_USER" ]]; then
    if [[ ! -t 0 ]]; then
      echo "ERROR: no hay una terminal para solicitar otro destino." >&2
      echo "Crea/enciende la VM, activa openssh-server y autoriza una clave SSH; después conecta por SSH o define ANSIBLE_LXC_IP y ANSIBLE_SSH_BOOTSTRAP_USER." >&2
      exit 1
    fi
    read -r -p "IP o nombre del destino SSH [$LXC_IP]: " requested_ip
    LXC_IP="${requested_ip:-$LXC_IP}"
    read -r -p "Usuario SSH para comprobar y preparar el destino: " SSH_BOOTSTRAP_USER
  fi
  if [[ -z "$SSH_BOOTSTRAP_USER" ]]; then
    echo "ERROR: debes indicar un usuario SSH." >&2
    exit 1
  fi
  if ! ssh_probe "$SSH_BOOTSTRAP_USER" "$LXC_IP"; then
    echo "ERROR: no se pudo conectar por SSH como '$SSH_BOOTSTRAP_USER' a '$LXC_IP'." >&2
    echo "Enciende/crea la VM, instala y activa openssh-server, comprueba la IP y autoriza una clave SSH desde este host." >&2
    echo "Verifica también la fingerprint del host en known_hosts antes de reintentar." >&2
    exit 1
  fi
fi

SUDO_PASSWORD=""
if [[ "$SSH_BOOTSTRAP_USER" != root ]]; then
  if ! ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
    'command -v sudo >/dev/null 2>&1'; then
    echo "ERROR: no está instalado sudo en '$LXC_IP'." >&2
    exit 1
  fi
  if ! ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" sudo -n true; then
    if [[ ! -t 0 ]]; then
      echo "ERROR: sudo requiere contraseña y no hay terminal para solicitarla." >&2
      echo "Ejecuta el paso 14 desde una terminal o configura sudo NOPASSWD." >&2
      exit 1
    fi
    if ! read -r -s -p "Contraseña sudo para $SSH_BOOTSTRAP_USER@$LXC_IP: " SUDO_PASSWORD; then
      printf '\n'
      echo "ERROR: no se pudo leer la contraseña sudo." >&2
      exit 1
    fi
    printf '\n'
    if [[ -z "$SUDO_PASSWORD" ]] ||
       ! printf '%s\n' "$SUDO_PASSWORD" |
         ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
           sudo -S -p '' -v >/dev/null 2>&1; then
      unset SUDO_PASSWORD
      echo "ERROR: la contraseña sudo no es válida o sudo rechazó la autenticación." >&2
      exit 1
    fi
  fi
fi
if ! ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
  'getent passwd alumno >/dev/null && getent passwd root >/dev/null'; then
  echo "ERROR: el destino debe tener las cuentas alumno y root, usadas por los Jenkinsfiles." >&2
  exit 1
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
for account in alumno root; do
  key_file="$SSH_DIR/ansible_lxc_${account}"
  if [[ ! -f "$key_file" ]]; then
    if credential_exists "ansible-lxc-${account}-ssh"; then
      echo "ERROR: Jenkins ya tiene ansible-lxc-${account}-ssh, pero falta $key_file." >&2
      echo "Restaura la clave privada desde una copia segura; no se puede regenerar sin perder acceso." >&2
      exit 1
    fi
    ssh-keygen -q -t ed25519 -N '' -C "jenkins-ansible-lxc-${account}" -f "$key_file"
  fi
  chmod 600 "$key_file"
  if [[ ! -f "$key_file.pub" ]]; then
    ssh-keygen -y -f "$key_file" > "$key_file.pub"
  fi
  chmod 644 "$key_file.pub"
done

TMP_DIR="$(mktemp -d)"
COOKIES="$TMP_DIR/cookies"
trap 'rm -rf "$TMP_DIR"' EXIT
CRUMB_JSON="$(curl -fsS -u "$AUTH" -c "$COOKIES" "$JENKINS_URL/crumbIssuer/api/json")"
CRUMB="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["crumb"])' <<<"$CRUMB_JSON")"
FIELD="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["crumbRequestField"])' <<<"$CRUMB_JSON")"

create_ssh_credential() {
  local account="$1" key_file="$2" credential_id="ansible-lxc-${1}-ssh" description
  description="SSH key for the ${account} account on ${SSH_BOOTSTRAP_USER}@${LXC_IP}"
  if credential_exists "$credential_id"; then
    echo "Jenkins credential '$credential_id' already exists."
    return
  fi
  local json_file code
  json_file="$TMP_DIR/$credential_id.json"
  python3 - "$credential_id" "$account" "$description" "$key_file" > "$json_file" <<'PY'
import json
import pathlib
import sys
credential_id, username, description, key_path = sys.argv[1:]
print(json.dumps({"credentials": {
    "scope": "GLOBAL",
    "id": credential_id,
    "username": username,
    "privateKeySource": {
        "value": "0",
        "privateKey": pathlib.Path(key_path).read_text(),
        "stapler-class": "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey$DirectEntryPrivateKeySource",
    },
    "passphrase": "",
    "description": description,
    "$class": "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey",
}}))
PY
  chmod 600 "$json_file"
  code="$(curl -sS -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" \
    --data-urlencode "json@$json_file" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
    -o /dev/null -w '%{http_code}')"
  rm -f "$json_file"
  case "$code" in
    200|201|302)
      if credential_exists "$credential_id"; then
        echo "Jenkins credential '$credential_id' is available."
      else
        echo "ERROR: HTTP $code but Jenkins did not store '$credential_id'." >&2
        return 1
      fi
      ;;
    *) echo "ERROR: Jenkins returned HTTP $code creating '$credential_id'." >&2; return 1 ;;
  esac
}

create_secret_text() {
  local credential_id="$1" value="$2" description="$3"
  if credential_exists "$credential_id"; then
    echo "Jenkins credential '$credential_id' already exists."
    return
  fi
  local json code
  json="$(python3 - "$credential_id" "$value" "$description" <<'PY'
import json
import sys
credential_id, secret, description = sys.argv[1:]
print(json.dumps({"credentials": {
    "scope": "GLOBAL",
    "id": credential_id,
    "secret": secret,
    "description": description,
    "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl",
}}))
PY
)"
  code="$(curl -sS -u "$AUTH" -b "$COOKIES" -H "$FIELD: $CRUMB" \
    --data-urlencode "json=$json" \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
    -o /dev/null -w '%{http_code}')"
  case "$code" in
    200|201|302)
      if credential_exists "$credential_id"; then
        echo "Jenkins credential '$credential_id' is available."
      else
        echo "ERROR: HTTP $code but Jenkins did not store '$credential_id'." >&2
        return 1
      fi
      ;;
    *) echo "ERROR: Jenkins returned HTTP $code creating '$credential_id'." >&2; return 1 ;;
  esac
}

create_secret_text "$IP_CREDENTIAL_ID" "$LXC_IP" "Ansible SSH target ($SSH_BOOTSTRAP_USER@$LXC_IP)"
create_ssh_credential alumno "$SSH_DIR/ansible_lxc_alumno"
create_ssh_credential root "$SSH_DIR/ansible_lxc_root"

install_public_key() {
  local account="$1" pub_file="$2" encoded_key remote_script encoded_script remote_command
  encoded_key="$(base64 < "$pub_file" | tr -d '\n')"
  remote_script="$(cat <<'REMOTE'
set -euo pipefail
account="$1"
encoded_key="$2"
home_dir="$(getent passwd "$account" | cut -d: -f6)"
primary_group="$(id -gn "$account")"
ssh_dir="$home_dir/.ssh"
authorized_keys="$ssh_dir/authorized_keys"
key="$(printf '%s' "$encoded_key" | base64 -d)"
install -d -m 0700 -o "$account" -g "$primary_group" "$ssh_dir"
touch "$authorized_keys"
chown "$account:$primary_group" "$authorized_keys"
chmod 0600 "$authorized_keys"
if ! grep -Fqx -- "$key" "$authorized_keys"; then
  printf '%s\n' "$key" >> "$authorized_keys"
fi
chown "$account:$primary_group" "$authorized_keys"
REMOTE
)"
  encoded_script="$(printf '%s' "$remote_script" | base64 | tr -d '\n')"
  if [[ "$SSH_BOOTSTRAP_USER" == root ]]; then
    remote_command="bash -c 'printf \"%s\" \"\$0\" | base64 -d | bash -s -- \"\$1\" \"\$2\"' $encoded_script $account $encoded_key"
    ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
      "$remote_command"
  elif [[ -n "$SUDO_PASSWORD" ]]; then
    remote_command="sudo -S -p '' bash -c 'printf \"%s\" \"\$0\" | base64 -d | bash -s -- \"\$1\" \"\$2\"' $encoded_script $account $encoded_key"
    printf '%s\n' "$SUDO_PASSWORD" |
      ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
        "$remote_command"
  else
    remote_command="sudo -n bash -c 'printf \"%s\" \"\$0\" | base64 -d | bash -s -- \"\$1\" \"\$2\"' $encoded_script $account $encoded_key"
    ssh "${SSH_OPTIONS[@]}" "${SSH_IDENTITY_OPTIONS[@]}" -l "$SSH_BOOTSTRAP_USER" "$LXC_IP" \
      "$remote_command"
  fi
  echo "SSH public key installed for '$account' on $LXC_IP via $SSH_BOOTSTRAP_USER."
}

install_public_key alumno "$SSH_DIR/ansible_lxc_alumno.pub"
install_public_key root "$SSH_DIR/ansible_lxc_root.pub"
unset SUDO_PASSWORD
echo "Ansible credentials ready for $LXC_IP (SSH bootstrap user: $SSH_BOOTSTRAP_USER)."
