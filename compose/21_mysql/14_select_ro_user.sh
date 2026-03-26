#!/bin/bash

set -e

docker compose exec mysql mysql -ureadonly_user -pReadOnly123! -e "SELECT * FROM appdb.usuarios;"