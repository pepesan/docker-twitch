# 77_ansible_docker_uninstall

Ejecuta `ejemplos-ansible/14_docker/tasks/docker_uninstall.yaml` para desinstalar Docker en Ubuntu 26.04.

> **Destructivo:** el playbook borra `/var/lib/docker`, `/var/lib/containerd` y `/etc/docker`. Se pierden contenedores, imágenes y volúmenes. No lo ejecutes en un host compartido ni con datos que quieras conservar.

## Ejecución manual

Este job tiene una protección contra borrados accidentales. En Jenkins, abre **77_ansible_docker_uninstall** y selecciona **Build with Parameters**. Marca `CONFIRM_DATA_LOSS` y confirma el build. Si se lanza sin marcarlo (su valor predeterminado es `false`), el job falla intencionadamente antes de ejecutar el playbook; no se desinstala Docker.

También puedes lanzarlo con el script del ejemplo, que exige una segunda confirmación local y envía el parámetro requerido a Jenkins:

```bash
./00_create_credentials.sh
./01_create.sh
CONFIRM_DOCKER_UNINSTALL=YES ./02_build.sh
./03_check.sh
```

La confirmación autoriza a borrar `/var/lib/docker`, `/var/lib/containerd` y `/etc/docker`, incluidos contenedores, imágenes y volúmenes. Úsalo únicamente en una VM desechable y después de comprobar que no hay datos que conservar. El runner `98_test_pipelines.sh all` omite este ejemplo por defecto.
