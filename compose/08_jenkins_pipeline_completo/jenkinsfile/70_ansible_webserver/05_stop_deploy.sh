#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
./scripts/stop_ansible_lxc_example.sh 70
