# 76_ansible_docker_compose_mariadb_uninstall

Detiene y elimina los contenedores MariaDB/Adminer, la red Compose y los ficheros de despliegue creados por el ejemplo 75.

**Conserva** el volumen `deploy-mariadb_mariadb_data` y los datos. No desinstala Docker. Ejecútalo después del 75.

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

Requiere Docker y Compose instalados por el ejemplo 72, y las credenciales SSH de la serie 70. Verifica que ya no quedan los contenedores, la red ni los ficheros de Compose y que el volumen persiste.