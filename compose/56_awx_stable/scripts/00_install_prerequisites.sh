#!/usr/bin/env bash
# Instala en la máquina el software necesario para clonar y compilar la
# imagen de desarrollo de AWX: git, make, Docker (con BuildKit, ya
# incluido en Docker moderno), el plugin docker-compose y Ansible con las
# colecciones que usan los playbooks internos del repo ansible/awx.
# Ejecutar una sola vez, con permisos de sudo.
set -euo pipefail

sudo apt update
sudo apt install -y git make python3-pip docker-compose-plugin

pip3 install --user ansible-core
~/.local/bin/ansible-galaxy collection install community.docker community.general ansible.posix

echo "Prerrequisitos instalados. Comprueba que tu usuario está en el grupo docker:"
echo "  groups \$USER | grep -q docker || sudo usermod -aG docker \$USER && newgrp docker"
