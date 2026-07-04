#!/bin/bash
# Lanza y espera el build de este job. Usa build_job_input.sh (no el
# generico build_job.sh): este Jenkinsfile tiene un "input" que hay que
# aprobar solo para poder verificarlo sin intervencion manual.
set -e
cd "$(dirname "$0")"
NAME="$(basename "$(pwd)")"
../../scripts/build_job_input.sh "$NAME"
