# 61_docker_plugin_external

Ejemplo de ejecución de pipelines en **contenedores Docker efímeros remotos**, utilizando una nube Docker ejecutada en un **contenedor LXC/LXD** (`docker-external`).

> [!IMPORTANT]
> La API Docker externa de este laboratorio usa TLS mutuo en el puerto
> `2376`; no se expone el puerto inseguro `2375`. Consulta
> [SECURITY_TLS.md](SECURITY_TLS.md) para entender la configuración.

---

## ¿Cómo funciona este ejemplo?

A diferencia del ejemplo `60` (que utiliza el motor Docker local del host a través de un socket UNIX), este pipeline solicita un agente con la etiqueta **`docker-agent-externo`**.

Jenkins redirigirá esta petición a la nube llamada `docker-external`, configurada para comunicarse mediante mTLS con `tcp://10.207.154.80:2376`. La credencial de cliente se registra en Jenkins con el identificador `docker-external-tls-creds`.

El ciclo de ejecución es idéntico al local:
1. Jenkins solicita la creación del agente.
2. El demonio de Docker remoto dentro de LXC arranca el contenedor de la imagen `jenkins/inbound-agent:alpine`.
3. Jenkins se conecta al proceso del agente mediante el conector Docker `attach`.
4. El pipeline ejecuta las fases dentro del contenedor remoto en LXC.
5. Al terminar, el contenedor se destruye del host LXC y la entrada en Jenkins se limpia automáticamente.

---

## Requisitos Previos

La forma recomendada de preparar toda la infraestructura y ejecutar el ejemplo desde cero es:

```shell
./98_test_pipelines.sh 61
```

La suite crea o arranca el LXC, instala y configura Docker, verifica la conexión mTLS, inicia o recarga Jenkins y finalmente ejecuta el job.

Para preparar los componentes manualmente desde el directorio raíz:

```shell
# 1. Crear o arrancar el contenedor LXC dedicado
./10_create_lxc_docker_node.sh

# 2. Instalar/configurar Docker y exponer la API mTLS en 2376
./11_install_docker_lxc.sh

# 3. Arrancar Jenkins si todavía no está en ejecución
./01_launch.sh
```

Los dos primeros scripts son idempotentes. `11_install_docker_lxc.sh` reutiliza los certificados mientras sean válidos; si Jenkins ya está ejecutándose, lo reinicia y espera a que vuelva a estar disponible para recargar `docker-external-tls-creds`. Esto evita errores `PKIX path building failed` causados por conservar una CA anterior en memoria.

---

## Cómo Probarlo

```shell
./01_create.sh   # Registra el job '61_docker_plugin_external' en Jenkins
./02_build.sh    # Lo lanza y bloquea la consola esperando el resultado
./03_check.sh    # Muestra los logs de consola de la última ejecución
./04_delete.sh   # Elimina el job de Jenkins
```

### Verificación del Host LXC (Durante la Compilación)
Mientras el script `./02_build.sh` esté esperando la build, puedes abrir otra terminal en tu host y ejecutar:

```shell
lxc exec jenkins-external-docker -- docker ps
```

Verás que el contenedor efímero se está ejecutando físicamente dentro del nodo LXC, aislando completamente las cargas de compilación del host principal de Jenkins.
