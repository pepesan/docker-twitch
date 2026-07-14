# 55_deploy_docker_compose_lxc

Despliegue de una aplicación multicontenedor (PostgreSQL + aplicación web Alpine) usando `docker compose` en un servidor LXC remoto a través de SSH.

## 🛠️ ¿Cómo funciona este ejemplo?
Este pipeline demuestra cómo desplegar arquitecturas complejas definidas en un archivo de Compose remoto:
1. **Fase de Preparación**: Escribe dinámicamente un archivo `compose.yaml` en el workspace de Jenkins. Este archivo define un servicio de base de datos (`db`) y un servicio de aplicación (`app`). El servicio `app` tiene una dependencia condicional que requiere que `db` pase con éxito su test de salud (`service_healthy`) antes de iniciarse.
2. **Fase de Transferencia**: Copia el archivo `compose.yaml` al directorio `/tmp` de la máquina LXC remota utilizando `scp`:
   ```bash
   scp -i $SSH_KEY ... compose.yaml root@$LXC_IP:/tmp/compose-lxc.yaml
   ```
3. **Fase de Despliegue**: Inicia el proyecto usando `docker compose up -d` en el servidor LXC remoto de forma aislada (usando el nombre de proyecto `demo-lxc-compose`).
4. **Fase de Verificación**: Verifica remotamente el estado del stack. Realiza un bucle de consulta para leer los logs de `app` y confirmar que el contenedor web solo arrancó cuando la base de datos PostgreSQL ya estaba completamente activa (`healthy`).

---

## 📋 Requisitos Previos y Preparación
Para poder ejecutar este ejemplo se necesitan los siguientes componentes configurados en el laboratorio:

1. **Host LXC con Docker (`jenkins-external-docker`)**:
   * Debe estar creado y configurado con la IP fija `10.207.154.80`.
   * El servicio Docker debe estar corriendo y tener instalado el plugin `docker-compose-plugin` (instalado automáticamente por `11_install_docker_lxc.sh`).
   * SSH (`22`) expuesto en el contenedor LXC.
   * Se realiza de manera automática ejecutando:
     ```shell
     ./10_create_lxc_docker_node.sh
     ./11_install_docker_lxc.sh
     ```

2. **Credenciales en Jenkins**:
   * **`agent-ssh-key`** (Clave SSH privada): Jenkins la utiliza para autenticarse como `root` en la máquina LXC. La clave pública correspondiente (`config/ssh/id_ed25519.pub`) es inyectada automáticamente en `/root/.ssh/authorized_keys` del LXC por el script `11_install_docker_lxc.sh`.
   * **`lxc-server-ip`** (Texto Secreto): Almacena de forma segura la dirección IP del servidor LXC (`10.207.154.80`). Se crea de manera automática al inicializar el entorno mediante el script de preparación `./00_create_credentials.sh` de este ejemplo.

3. **Seguridad contra Fugas de Secretos (Evitando Insecure Interpolation)**:
   * Los scripts `sh` utilizan comillas simples (`'''`) en lugar de comillas dobles. Esto evita la interpolación insegura por parte de Groovy y delega la lectura de las variables `$SSH_KEY` y `$LXC_IP` al shell de ejecución de Jenkins, de forma que los datos sensibles se enmascaran automáticamente en la salida como `****`.

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
lxc exec jenkins-external-docker -- docker compose -f /tmp/compose-lxc.yaml -p demo-lxc-compose ps
```
