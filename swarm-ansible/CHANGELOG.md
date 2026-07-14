# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to Semantic Versioning.

## [Unreleased]

### Added
- **Ansible Playbooks for Laboratory Orchestration**: Created a complete set of sequential playbooks (from `00` to `30`) to replace the legacy shell scripts with idempotent and native Ansible tasks.
- **`00_instalar_lxd.yml`**: Automates snap installation and ZFS pool loopback initialization without requiring host-level ZFS utilities.
- **`01_crear_imagen_base.yml`**: Builds the custom base OS template with pre-configured SSH keys.
- **`02_check_requisitos.yml`**: Validates local commands, templates, network interface presence, and installs required Galaxy collections.
- **`03_crear_nodos.yml`**: Deploys the 8 container instances (3 managers, 2 workers, Portainer, and 2 load balancers) on LXD.
- **`05_swarm_init.yml`**: Boots the initial Swarm cluster and generates worker/manager join tokens.
- **`06_swarm_join_managers.yml`**: Automatically joins managers to form the 3-node Raft quorum.
- **`07_swarm_join_workers.yml`**: Joins workers to the Swarm cluster.
- **`08_verificar_cluster.yml`**: Diagnostics verification tool running `docker node ls` from the leader.
- **`10_probar_caida_nodo.yml`**: Automated simulation of a node crash (stopping LXD container) to verify rescheduled replica distribution.
- **`11_recuperar_cluster.yml`**: Automates rebalancing of the `web-demo` service replicas across all active workers after simulated node crash recovery.
- **`28_desinstalar_agente_portainer.yml`** and **`29_desinstalar_portainer.yml`**: Provide clean uninstallation of the Swarm Portainer Agent and Portainer Server respectively.
- **`30_destroy.yml`** (renamed from `12`): Safely destroys the LXD lab containers and sweeps tokens on confirmation.
- **`13_instalar_agente_portainer.yml`**: Added to deploy the Portainer Swarm Agent and automatically register the Swarm cluster in Portainer Server via REST API calls.
- **`run_all.sh`**: A master bash orchestration script that runs playbooks sequentially and supports bounds (e.g. `--hasta NN`).
- **`destroy_all.sh`**: An orchestration script to cleanly uninstall Portainer (28–29) and destroy all LXD containers (30) sequentially.
- **Ansible Installation Guide**: Documented PPA (`deb`) and Python 3 (`pipx`) installation methods for Ubuntu 24.04 and 26.04 in `README.md`, officially recommending `pipx` as Method A and placing PPA as Method B.

### Changed
- **`04_instalar_docker.yml`**:
  - Included `docker-buildx-plugin` as requested.
  - Replaced deprecated facts with modernized `ansible_facts` references.
  - Ensured both `docker` and `containerd` systemd services are enabled and started.
  - Implemented automatic stoppage/disabling of `unattended-upgrades` to prevent apt lock blockages in development.
  - Added `lock_timeout: 300` to all apt-related tasks.
- **`09_desplegar_servicio.yml`**:
  - Rewrote the replica convergence loop. Changed the filter to check for tasks in the actual `Running` state (using `.CurrentState` matching `^Running`) rather than matching the desired state, preventing HTTP connection refused timeouts during image download.
- **`12_instalar_portainer.yml`** (renamed from `11_instalar_portainer.yml`):
  - Split playbook: limited scope to Portainer Server installation (outside of Swarm) on the portainer node.
  - Added published port `8000:8000` to Portainer Server to accommodate TCP tunnels and edge agent setups.
  - Implemented automatic initial admin credential bootstrap (`admin` / `mipass`) using a bcrypt hash command parameter to avoid manual configuration and the security timeout error.
- **`02_check_requisitos.yml`**:
  - Integrated native, idempotent installation of Ansible Galaxy collections (`community.general`, `community.docker`, and `bgtor.portainer`) via `community.general.ansible_galaxy_install`.
- **`.gitignore`**:
  - Added `PLAN.md` to prevent local tracking and keep the workspace repository focused.

### Removed
- **Option B.2 (venv) from README.md**: Removed the Python 3 virtual environment (`venv`) installation instructions from the `README.md` guide as they were redundant and less optimal than the recommended `pipx` method.
