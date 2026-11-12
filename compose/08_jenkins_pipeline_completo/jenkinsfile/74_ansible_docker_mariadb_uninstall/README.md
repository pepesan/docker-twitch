# 74_ansible_docker_mariadb_uninstall

Retira el contenedor `mariadb` creado por el ejemplo 73 mediante `community.docker.docker_container state=absent`.

**Conserva** el volumen `mariadb-data-volume` y los datos de la base de datos. No desinstala Docker. Ejecútalo después del 73 y antes del 75, porque Compose también publica el puerto 3306.

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

Requiere Docker instalado por el ejemplo 72 y las credenciales SSH de la serie 70. La verificación comprueba que el contenedor ya no existe y que el volumen de datos sigue disponible.