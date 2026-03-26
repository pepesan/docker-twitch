#!/bin/bash

set -e

docker compose exec mysql mysql -uroot -proot -e "SELECT user, host, plugin FROM mysql.user;"

# caching_sha2_password: por defecto en MySQL 8
# mysql_native_password: método clásico de MySQL (anterior a la versión 8)
# sha256_password: alternativa más segura que mysql_native_password
# auth_socket (o unix_socket): Este método no usa contraseña.
# mysql_no_login: Un método especial. Impide el login