# 57_deploy_docker_compose_ansible_lxc

Despliegue de una aplicación multicontenedor (PostgreSQL + aplicación web Alpine) usando Ansible y `docker compose` en un servidor LXC remoto.

## 🛠️ ¿Cómo funciona este ejemplo?
Este pipeline combina la orquestación de Docker Compose con el aprovisionamiento automatizado y modular de Ansible:
1. **Contenedor Agente Efímero (Aislamiento de Entorno)**: La compilación corre dentro de un contenedor efímero de **`alpine:3.20`** montado en el built-in node, lo que asegura que las herramientas no contaminen el host de Jenkins.
2. **Instalación On-The-Fly**: Instala Ansible y el cliente de SSH al vuelo al iniciarse el pipeline (`apk add --no-cache ansible openssh-client`).
3. **Escritura del Stack y Playbook**: Genera dinámicamente en el workspace local el archivo `compose.yaml` y el playbook `playbook.yml`.
4. **Despliegue con Ansible**: Ansible se conecta al host LXC y ejecuta tres tareas estructuradas:
   * **Crear directorio**: Crea de forma segura el directorio `/tmp/ansible-compose` en el LXC remoto.
   * **Copiar archivos**: Copia el archivo `compose.yaml` generado localmente al host remoto mediante el módulo `copy` de Ansible.
   * **Iniciar el proyecto**: Ejecuta de forma remota `docker compose up -d` para arrancar la base de datos y la aplicación.
5. **Verificación**: Realiza un bucle de comprobación de logs remotos vía SSH para confirmar que el stack se inicializó correctamente y de forma coordinada.

---

## 📋 Requisitos Previos y Preparación
Para poder ejecutar este ejemplo se necesitan los siguientes componentes configurados en el laboratorio:

1. **Host LXC con Docker (`jenkins-external-docker`)**:
   * Debe estar creado y configurado con la IP fija `10.207.154.80`.
   * Docker y `docker-compose-plugin` instalados (completado automáticamente por `11_install_docker_lxc.sh`).
   * SSH (`22`) abierto.
   * Se realiza de manera automática ejecutando:
     ```shell
     ./10_create_lxc_docker_node.sh
     ./11_install_docker_lxc.sh
     ```

2. **Credenciales en Jenkins**:
   * **`agent-ssh-key`** (Clave SSH privada): Jenkins la utiliza para autenticarse como `root` en la máquina LXC. La clave pública correspondiente (`config/ssh/id_ed25519.pub`) es inyectada automáticamente en `/root/.ssh/authorized_keys` del LXC por el script `11_install_docker_lxc.sh`.
   * **`lxc-server-ip`** (Texto Secreto): Almacena de forma segura la dirección IP del servidor LXC (`10.207.154.80`). Se crea de manera automática al inicializar el entorno mediante el script de preparación `./00_create_credentials.sh` de este ejemplo.

3. **Seguridad contra Fugas de Secretos (Evitando Insecure Interpolation)**:
   * Los scripts `sh` utilizan comillas simples (`'''`) en lugar de comillas dobles. Esto evita la interpolación por parte de Groovy y delega la lectura al shell de ejecución de Jenkins, de forma que los datos sensibles se enmascaran automáticamente en la salida como `****`.

---

## 🚀 Cómo Ejecutar y Probar

Ejecuta los siguientes scripts desde el directorio del ejemplo:

```shell
./01_create.sh      # Crea las credenciales 'lxc-server-ip' e inicializa el Job en Jenkins
./02_build.sh       # Lanza la ejecución de la compilación y espera el resultado (SUCCESS)
./05_stop_deploy.sh # Detiene y elimina el stack de Compose del LXC remoto
./03_check.sh       # Muestra el log completo del último build en Jenkins
./04_delete.sh      # Elimina el Job de Jenkins para mantener el servidor limpio
```

Para verificar que el stack sigue en ejecución en la máquina remota (antes de ejecutar `./05_stop_deploy.sh`), puedes ejecutar desde tu terminal local:
```shell
lxc exec jenkins-external-docker -- docker compose -f /tmp/ansible-compose/compose.yaml -p demo-ansible-compose ps
```
