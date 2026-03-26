#!/bin/bash

set -e

docker compose exec mysql mysql -ureadonly_user -pReadOnly123! -e "INSERT INTO appdb.usuarios (nombre, email) VALUES ('Pedro', 'pedro@email.com');"