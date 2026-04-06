#!/bin/bash

docker compose exec garage /garage -c /etc/garage.toml key create practica
# Anota el ID que se muestra en la salida del comando anterior, lo necesitarás para el siguiente paso
# anota el Secret KEY que se muestra en la salida del comando anterior, lo necesitarás para el siguiente paso
echo "Recuerda anotar el KEY ID y el Secret KEY que se muestran en la salida del comando anterior, los necesitarás para el script 10_configure_minio_cli_alias.sh"





