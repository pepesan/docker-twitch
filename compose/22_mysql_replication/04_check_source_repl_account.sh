#!/bin/bash

set -e

docker compose exec mysql-source mysql -u repl -preplpass


