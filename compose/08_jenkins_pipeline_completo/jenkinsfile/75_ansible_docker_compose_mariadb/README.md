# 75_ansible_docker_compose_mariadb

Ejecuta `ejemplos-ansible/14_docker/tasks/docker_compose_deploy_mariadb.yaml` para desplegar MariaDB y Adminer con Docker Compose.

## Requisitos y puertos

- Haber ejecutado el ejemplo 72 para instalar Docker Engine y Compose.
- El pipeline instala `python3-docker` en el destino, requisito de `community.docker`.
- Publica MariaDB en TCP/3307 y Adminer en TCP/8080. El Jenkinsfile cambia el puerto del Compose upstream en la copia temporal del workspace para coexistir con el ejemplo 73, que usa TCP/3306.

## Ejecución

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

El pipeline usa SSH como `alumno` con `become`, fuerza la actualización de `community.docker` a `3.10.2` o superior en el agente e instala `python3-docker` en el destino. Verifica MariaDB y Adminer sin exponer cookies de sesión en el log. El ejemplo 76 elimina contenedores, red y ficheros, pero conserva el volumen de Compose.
