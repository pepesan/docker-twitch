#!/usr/bin/env bash
sed -i 's/image: mariadb:11\.4/image: mariadb:11\.8/' compose.yaml

docker compose up -d


