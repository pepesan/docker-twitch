# 71_ansible_webserver_uninstall

Retira Nginx instalado por el ejemplo `70_ansible_webserver`. Ejecuta el playbook upstream `03_servidorweb/tasks_uninstall.yaml` del repositorio `pepesan/ejemplos-ansible` mediante SSH como `alumno` con `become`.

El pipeline comprueba que puede conectarse, detiene y deshabilita Nginx, desinstala el paquete `nginx` y verifica que el paquete ya no figure instalado y que el servicio no esté activo. No ejecuta `autoremove` ni borra otros paquetes o datos.

Ejecuta primero el ejemplo 70 para desplegar el servidor web; después usa el ciclo normal de este ejemplo:

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./04_delete.sh
```

La credencial de acceso y la IP se preparan con el paso común `14_create_ansible_credentials.sh`. Consulta la guía [ANSIBLE.md](../../ANSIBLE.md) para configurar el destino y Jenkins.
