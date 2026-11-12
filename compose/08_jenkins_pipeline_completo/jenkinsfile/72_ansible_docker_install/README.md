# 72_ansible_docker_install

Ejecuta `ejemplos-ansible/14_docker/tasks/docker_install.yaml` para instalar Docker Engine y Docker Compose en Ubuntu 26.04 Resolute.

## Requisitos

- Jenkins y las credenciales Ansible del ejemplo 70.
- Destino Ubuntu 26.04 (`resolute`) accesible por SSH.
- Esta instalación elimina paquetes Docker antiguos enumerados por el playbook; pruébala en la VM de laboratorio.

## Ejecución

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

El pipeline usa la clave de `root`, comprueba Docker y Compose al terminar y deja Docker instalado para los ejemplos 73 y 74. Este ejemplo no desinstala Docker como limpieza.
