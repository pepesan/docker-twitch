# 61_docker_plugin_external

Ejemplo de ejecución de pipelines en **contenedores Docker efímeros remotos**, utilizando una nube Docker ejecutada en un **contenedor LXC/LXD** (`docker-external`).

> [!IMPORTANT]
> **Seguridad en Producción:** Exponer la API de Docker sin cifrar en el puerto `2375` solo se recomienda en laboratorios locales controlados. Para producción, lee la [Guía de Securización por TLS (mTLS)](file:///home/pepesan/IdeaProjects/docker-twitchv2/compose/08_jenkins_pipeline_completo/jenkinsfile/61_docker_plugin_external/SECURITY_TLS.md) para aprender a proteger el demonio de Docker y habilitar conexiones seguras en el puerto `2376`.

---

## ¿Cómo funciona este ejemplo?

A diferencia del ejemplo `60` (que utiliza el motor Docker local del host a través de un socket UNIX), este pipeline solicita un agente con la etiqueta **`docker-agent-externo`**.

Jenkins redirigirá esta petición a la nube llamada `docker-external` (configurada para comunicarse por TCP con la máquina virtual LXC en la IP fija `10.207.154.80:2375`).

El ciclo de ejecución es idéntico al local:
1. Jenkins solicita la creación del agente.
2. El demonio de Docker remoto dentro de LXC arranca el contenedor de la imagen `jenkins/inbound-agent:alpine`.
3. El agente se conecta al Controller de Jenkins.
4. El pipeline ejecuta las fases dentro del contenedor remoto en LXC.
5. Al terminar, el contenedor se destruye del host LXC y la entrada en Jenkins se limpia automáticamente.

---

## Requisitos Previos

Para poder probar este ejemplo, debes tener levantado el entorno de la nube externa ejecutando los scripts de la raíz:

```shell
# 1. Crear el contenedor LXC dedicado
./10_create_lxc_docker_node.sh

# 2. Instalar Docker y exponer la API TCP (2375) en LXC
./11_install_docker_lxc.sh

# 3. Vincular y reiniciar el Controller de Jenkins con la IP asignada
./12_configure_jenkins_remote_docker.sh
```

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
