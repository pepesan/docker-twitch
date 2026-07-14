# 58_deploy_docker_lxc_tls

Despliegue de un contenedor individual usando la API nativa de Docker sobre TLS (mTLS) en un servidor LXC remoto.

## 🛠️ ¿Cómo funciona este ejemplo?
Este pipeline demuestra cómo conectarse a un demonio de Docker remoto de forma directa y segura a nivel de API (sin utilizar túneles SSH):
1. **Fase de Construcción**: Construye la imagen Docker localmente en el Jenkins Controller (`demo-lxc-tls-app`).
2. **Fase de Conexión TLS**: Configura las variables del cliente Docker local para apuntar al socket de red del servidor LXC remoto expuesto en el puerto `2376`:
   ```bash
   export DOCKER_HOST="tcp://$LXC_IP:2376"
   export DOCKER_TLS_VERIFY=1
   ```
   Como el Controller de Jenkins monta los certificados generados en `/var/jenkins_home/certs`, el cliente Docker de Jenkins los utiliza automáticamente para autenticarse mutuamente con el servidor remoto (mTLS).
3. **Fase de Carga y Despliegue**: Sube e instala la imagen en el LXC usando `docker save | docker load` a través de la API TLS, detiene el contenedor anterior y levanta el nuevo contenedor.
4. **Fase de Verificación**: Consulta el estado de ejecución y logs directamente en el host remoto usando la misma API de red segura.

---

## 📋 Requisitos Previos y Preparación
Para poder ejecutar este ejemplo se necesitan los siguientes componentes configurados en el laboratorio:

1. **Host LXC con Docker (`jenkins-external-docker`)**:
   * Debe estar creado y configurado con la IP fija `10.207.154.80`.
   * Docker configurado en modo seguro (`daemon.json` con `tlsverify: true`) en el puerto `2376` (completado automáticamente por `11_install_docker_lxc.sh`).
   * Se realiza de manera automática ejecutando:
     ```shell
     ./10_create_lxc_docker_node.sh
     ./11_install_docker_lxc.sh
     ```

2. **Credenciales en Jenkins**:
   * **`lxc-server-ip`** (Texto Secreto): Almacena la dirección IP del servidor LXC (`10.207.154.80`). Se crea automáticamente al inicializar el entorno mediante el script de preparación `./00_create_credentials.sh` de este ejemplo.

3. **Seguridad contra Fugas de Secretos**:
   * Los scripts `sh` utilizan comillas simples (`'''`) en lugar de comillas dobles. Esto delega la lectura de la variable `$LXC_IP` al shell de Jenkins, ocultando la dirección IP remota como `****` en los logs.

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

Para verificar que el contenedor sigue en ejecución en la máquina remota (antes de ejecutar `./05_stop_deploy.sh`), puedes ejecutar desde tu terminal local:
```shell
lxc exec jenkins-external-docker -- docker ps --filter name=demo-lxc-tls-app
```
