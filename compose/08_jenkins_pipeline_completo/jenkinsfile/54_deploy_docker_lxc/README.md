# 54_deploy_docker_lxc

Despliegue de un contenedor individual usando `docker run -d` en un servidor LXC remoto a través de un canal SSH directo desde Jenkins.

## 🛠️ ¿Cómo funciona este ejemplo?
Este pipeline realiza un despliegue idempotente y seguro siguiendo estos pasos:
1. **Fase de Construcción**: Genera dinámicamente un `Dockerfile` en el workspace de Jenkins y construye la imagen localmente (`demo-lxc-app:latest` y `demo-lxc-app:<BUILD_NUMBER>`).
2. **Fase de Transferencia**: Mediante una tubería (pipe) sobre SSH, exporta la imagen construida y la importa directamente en el motor Docker del LXC remoto sin necesidad de usar un registro intermedio:
   ```bash
   docker save $IMAGE:$BUILD_NUMBER | ssh -i $SSH_KEY ... root@$LXC_IP "docker load"
   ```
3. **Fase de Despliegue**: Detiene y elimina de forma segura cualquier contenedor previo del mismo proyecto en el LXC y arranca el nuevo contenedor.
4. **Fase de Verificación**: Realiza consultas remotas vía SSH (`docker ps` y `docker logs`) para comprobar que el servicio responde y está saludable.

---

## 📋 Requisitos Previos y Preparación
Para poder ejecutar este ejemplo se necesitan los siguientes componentes configurados en el laboratorio:

1. **Host LXC con Docker (`jenkins-external-docker`)**:
   * Debe estar creado y configurado con la IP fija `10.207.154.80`.
   * El servicio Docker debe estar corriendo y el puerto SSH (`22`) abierto.
   * Se realiza de manera automática ejecutando:
     ```shell
     ./10_create_lxc_docker_node.sh
     ./11_install_docker_lxc.sh
     ```

2. **Credenciales en Jenkins**:
   * **`agent-ssh-key`** (Clave SSH privada): Jenkins la utiliza para autenticarse como `root` en la máquina LXC. La clave pública correspondiente (`config/ssh/id_ed25519.pub`) es inyectada automáticamente en `/root/.ssh/authorized_keys` del LXC por el script `11_install_docker_lxc.sh`.
   * **`lxc-server-ip`** (Texto Secreto): Almacena de forma segura la dirección IP del servidor LXC (`10.207.154.80`). Se crea de manera automática al inicializar el entorno mediante el script de preparación `./00_create_credentials.sh` de este ejemplo.

3. **Seguridad contra Fugas de Secretos (Evitando Insecure Interpolation)**:
   * Los scripts `sh` utilizan comillas simples (`'''`) en lugar de comillas dobles. Esto previene que Jenkins interprete y exponga las credenciales críticas (`$SSH_KEY` y `$LXC_IP`) en el código de Groovy antes de la ejecución. Jenkins enmascara automáticamente el valor de estas credenciales en los logs de salida como `****`.

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
lxc exec jenkins-external-docker -- docker ps --filter name=demo-lxc-app
```
