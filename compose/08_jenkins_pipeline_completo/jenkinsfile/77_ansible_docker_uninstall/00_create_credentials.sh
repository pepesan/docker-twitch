#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
../../14_create_ansible_credentials.sh "$@"
