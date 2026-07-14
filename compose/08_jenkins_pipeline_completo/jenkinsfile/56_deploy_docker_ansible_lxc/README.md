# 56_deploy_docker_ansible_lxc

Despliegue de un contenedor individual usando Ansible y `docker run` en un servidor LXC remoto.

## 🛠️ ¿Cómo funciona este ejemplo?
Este pipeline introduce el uso de herramientas de automatización profesionales (Ansible) desde Jenkins de una forma limpia y modular:
1. **Contenedor Agente Efímero (Aislamiento de Entorno)**: El pipeline no corre directamente en el Jenkins Controller principal. En su lugar, utiliza un contenedor efímero de **`alpine:3.20`** (con la directiva `agent { docker { ... } }`).
2. **Instalación On-The-Fly**: Para mantener limpio el host de Jenkins, la herramienta **Ansible** y el cliente SSH se instalan al vuelo dentro del contenedor de Alpine al iniciarse la pipeline:
   ```bash
   apk add --no-cache ansible openssh-client
   ```
   Esto asegura que el sistema siempre use una versión limpia de Ansible sin necesidad de empaquetar o mantener imágenes Docker personalizadas de gran tamaño.
3. **Escritura del Playbook**: Genera dinámicamente el archivo `playbook.yml` que describe la tarea de Ansible (detener e iniciar el contenedor de forma idempotente).
4. **Ejecución de Ansible**: Ejecuta el comando `ansible-playbook` apuntando al host LXC, utilizando la clave privada de Jenkins y la IP remota del servidor recuperadas de forma segura desde las credenciales:
   ```bash
   ansible-playbook -i "$LXC_IP," -u root --private-key="$SSH_KEY" ... playbook.yml
   ```
5. **Verificación**: Realiza consultas remotas al contenedor levantado (`demo-ansible-app`) mediante comandos SSH para comprobar sus logs.

---

## 📋 Requisitos Previos y Preparación
Para poder ejecutar este ejemplo se necesitan los siguientes componentes configurados en el laboratorio:

1. **Host LXC con Docker (`jenkins-external-docker`)**:
   * Debe estar creado y configurado con la IP fija `10.207.154.80`.
   * Docker instalado y corriendo.
   * Se realiza de manera automática ejecutando:
     ```shell
     ./10_create_lxc_docker_node.sh
     ./11_install_docker_lxc.sh
     ```

2. **Credenciales en Jenkins**:
   * **`agent-ssh-key`** (Clave SSH privada): Jenkins la utiliza para autenticarse como `root` en la máquina LXC. La clave pública correspondiente (`config/ssh/id_ed25519.pub`) es inyectada automáticamente en `/root/.ssh/authorized_keys` del LXC por el script `11_install_docker_lxc.sh`.
   * **`lxc-server-ip`** (Texto Secreto): Almacena de forma segura la dirección IP del servidor LXC (`10.207.154.80`). Se crea de manera automática al inicializar el entorno mediante el script de preparación `./00_create_credentials.sh` de este ejemplo.

3. **Seguridad contra Fugas de Secretos (Evitando Insecure Interpolation)**:
   * Los scripts `sh` utilizan comillas simples (`'''`) en lugar de comillas dobles. Esto evita la interpolación de variables por parte de Groovy y delega la lectura al shell del contenedor. Jenkins enmascara la clave privada y la dirección IP sensible mostrándolas como `****` en los logs.

---

## 🚀 Cómo Ejecutar y Probar

Ejecuta los siguientes scripts desde el directorio del ejemplo:

```shell
./01_create.sh      # Crea las credenciales 'lxc-server-ip' e inicializa el Job en Jenkins
./02_build.sh       # Lanza la ejecución de la compilación y espera el resultado (SUCCESS)
./05_stop_deploy.sh # Detiene y elimina el contenedor de prueba del LXC remoto
./03_check.sh       # Muestra el log completo del último build en Jenkins
./04_delete.sh      # Elimina el Job de Jenkins para mantener el servidor limpio
```

Para verificar que el contenedor sigue vivo en el host remoto (antes de ejecutar la limpieza con `05_stop_deploy.sh`), puedes ejecutar desde tu terminal local:
```shell
lxc exec jenkins-external-docker -- docker ps --filter name=demo-ansible-app
```
