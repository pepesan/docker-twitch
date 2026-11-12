# 73_ansible_docker_mariadb

Ejecuta `ejemplos-ansible/14_docker/tasks/docker_deploy_mariadb.yaml` para desplegar el contenedor MariaDB `mariadb` con el volumen `mariadb-data-volume`.

## Requisitos y puertos

- Haber ejecutado el ejemplo 72 para instalar Docker.
- El pipeline instala `python3-docker` en el destino, requisito de `community.docker`.
- Publica TCP/3306. El Compose del ejemplo 75 usa TCP/3307, así que ambos despliegues pueden permanecer activos simultáneamente.

## Ejecución

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

El pipeline usa SSH como `alumno` con `become`, fuerza la actualización de `community.docker` a `3.10.2` o superior en el agente e instala `python3-docker` en el destino. Verifica que MariaDB queda lista. El ejemplo 74 retira el contenedor y conserva `mariadb-data-volume` con los datos.
