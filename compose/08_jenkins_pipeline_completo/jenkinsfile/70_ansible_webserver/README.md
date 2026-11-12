# 70_ansible_webserver

Instala y verifica Nginx en el host Ansible usando `ejemplos-ansible/03_servidorweb/tasks.yaml`.

## Requisitos

- Jenkins Controller activo en `http://localhost:8082`.
- Destino SSH encendido y accesible desde Jenkins en `10.207.154.161`; cuenta `alumno` con sudo sin contraseña y cuenta `root`.
- El E2E `98_test_ansible_pipelines.sh` requiere además que LXD esté disponible en el host.

`00_create_credentials.sh` delega en `../../14_create_ansible_credentials.sh`. Este paso no depende de LXD: prueba `root@10.207.154.161` y, si falla, solicita IP y usuario SSH. Si no logra conectar, aborta sin generar claves ni credenciales e indica cómo preparar el destino. Tras conectar, genera claves privadas Ed25519 en `config/ssh/` (excluido de Git), crea las credenciales globales `ansible-lxc-ip`, `ansible-lxc-alumno-ssh` y `ansible-lxc-root-ssh`, e instala solo las claves públicas para `alumno` y `root`. El usuario de preparación distinto de root puede introducir su contraseña sudo cuando se solicite; no se almacena. Jenkins genera `inventory.ini` y `ansible.cfg` dentro del workspace de cada build.

## Ejecución

```bash
./00_create_credentials.sh
./01_create.sh
./02_build.sh
./03_check.sh
./05_stop_deploy.sh  # detiene Nginx; no desinstala el paquete
./04_delete.sh
```

El pipeline usa la cuenta `alumno` con `become`, clona el repositorio de Ansible y comprueba Nginx mediante una petición HTTP local. Usa `tasks.yaml`, que no cambia las reglas del firewall.
