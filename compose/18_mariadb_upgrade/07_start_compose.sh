#!/usr/bin/env bash
sed -i 's/image: mariadb:11\.8/image: mariadb:12\.1/' compose.yaml

docker compose up -d


