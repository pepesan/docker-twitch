# 60_docker_plugin_basic

Ejemplo básico de ejecución de pipelines en **contenedores Docker efímeros** dinámicos, utilizando el **Jenkins Docker Plugin**.

---

## ¿Cómo funciona el Docker Plugin en Jenkins?

En lugar de tener agentes permanentes (como `agent1` y `agent2`) corriendo continuamente y consumiendo recursos del host, el plugin de Docker permite tratar a tu motor Docker local como una **nube de recursos bajo demanda**.

El flujo de ejecución en segundo plano funciona de la siguiente manera:
1. **Petición del Agente:** El pipeline arranca y solicita ejecutarse en un nodo con la etiqueta `docker-agent-efimero`.
2. **Aprovisionamiento Dinámico:** Jenkins detecta que no hay ningún agente fijo libre con esa etiqueta. Al estar configurada la nube Docker, el Controller se conecta al socket de Docker del host (`/var/run/docker.sock`) y ejecuta un contenedor al vuelo basado en la imagen de agente configurada.
3. **Conexión:** El nuevo contenedor arranca y establece una conexión automática (vía comando `attach` de Docker) con el Controller de Jenkins.
4. **Ejecución:** El pipeline se ejecuta dentro de este contenedor efímero.
5. **Periodo de Gracia y Destrucción:** Al terminar la build (sea éxito o fallo), el nodo entra en un breve periodo de gracia (configurado en 1 minuto máximo de inactividad, pero destruido tras unos segundos) para volcar los logs de consola de forma limpia, y Jenkins ordena a Docker detener y eliminar (`docker rm -f`) el contenedor de forma inmediata.

---

## ¿Dónde y cómo se configura de forma automatizada (Código)?

El soporte completo para este flujo se encuentra totalmente automatizado a nivel de infraestructura en el directorio de configuración global del proyecto:

1. **Instalación del Plugin:**
   * Archivo: [config/plugins.txt](file:///home/pepesan/IdeaProjects/docker-twitchv2/compose/08_jenkins_pipeline_completo/config/plugins.txt)
   * Se añade la línea `docker-plugin` para que el script de construcción de la imagen de Jenkins descargue e instale el plugin automáticamente sin intervenciones manuales en la interfaz web.
2. **Definición de la Nube y Plantilla (JCasC):**
   * Archivo: [config/casc.yaml](file:///home/pepesan/IdeaProjects/docker-twitchv2/compose/08_jenkins_pipeline_completo/config/casc.yaml)
   * Bajo la sección `jenkins.clouds`, declaramos la nube `docker-local` conectada a `unix:///var/run/docker.sock`.
   * Registramos una plantilla de contenedor con la etiqueta `docker-agent-efimero` utilizando la imagen `jenkins/inbound-agent:alpine`.
   * Se establece la estrategia de retención homogénea `retentionStrategy` con `idleMinutes: 1` para garantizar la destrucción inmediata del contenedor tras finalizar el trabajo.

---

## Configuración Manual desde la Interfaz Web (Alternativa a Código)

Si en lugar de utilizar archivos de configuración automatizados prefieres realizar la instalación y configuración de forma manual desde el panel de Jenkins, debes seguir estos pasos:

### Paso 1: Instalar el Plugin
1. Ve a **Administrar Jenkins (Manage Jenkins) > Plugins**.
2. En la pestaña **Plugins disponibles (Available plugins)**, busca **Docker** (el publicado por CloudBees/Nirima).
3. Marca la casilla del plugin y haz clic en **Instalar**.
4. Reinicia el servidor Jenkins si la instalación lo requiere.

### Paso 2: Crear y Configurar la Nube Docker
1. Ve a **Administrar Jenkins (Manage Jenkins) > Clouds (Nubes)**.
2. Haz clic en el botón **New Cloud (Nueva nube)** y selecciona **Docker**.
3. Nómbrala como `docker-local` y despliega la sección **Docker Cloud details**.
4. Asegúrate de que la casilla **Enabled** de esta sección esté marcada/habilitada.
5. En **Docker Host URI**, escribe la ruta al socket local:
   * `unix:///var/run/docker.sock`
6. Haz clic en **Test Connection** (Probar conexión). Debería mostrar la versión de Docker del host si la comunicación es correcta.

### Paso 3: Registrar la Plantilla del Agente Efímero
1. En esa misma pantalla de configuración de la nube, haz clic en **Docker Agent templates...** y luego en **Add Docker Template**.
2. Rellena los campos principales del agente:
   * **Labels (Etiquetas):** `docker-agent-efimero` (la que buscará el pipeline).
   * **Enabled:** Cambiar a **Enabled** (por defecto la interfaz lo crea como **Disabled** y hay que activarlo manualmente).
   * **Name:** Un nombre identificativo interno, por ejemplo: `agente-efimero-inbound`.
   * **Docker Image:** `jenkins/inbound-agent:alpine` (imagen oficial de agentes Jenkins).
   * **Remote File System Root:** `/home/jenkins/agent` (el directorio de trabajo dentro del contenedor).
   * **Usage (Uso):** Selecciona *Only build jobs with label expressions matching this node* (equivale al modo `EXCLUSIVE` para evitar que otros trabajos no deseados utilicen este nodo).
   * **Idle timeout (Tiempo de inactividad):** Cambiar el valor por defecto (que suele ser `10`) a **`1`** (esto equivale a la configuración `idleMinutes: 1` para que el contenedor efímero se destruya rápidamente y se borre de la interfaz tras finalizar la build).
3. En la sección **Connect method (Método de conexión)**, selecciona **Attach Docker container** (para que la comunicación sea directa a través del socket de Docker, eliminando la necesidad de configurar claves SSH o puertos TCP adicionales).
4. Haz clic en **Save (Guardar)**.

---

## Paso a paso para probar el ejemplo

### 1. Preparar el Entorno
Si ya has levantado el entorno general con los scripts de la raíz, tu Jenkins Controller ya tiene el plugin instalado y la configuración cargada. (Si estuvieras empezando de cero, con hacer `./00_init.sh` y `./01_launch.sh` ya se configuraría solo).

### 2. Dar de alta el Job en Jenkins
Desde la carpeta de este ejemplo, ejecuta el script de creación:
```shell
./01_create.sh
```
Esto creará el trabajo `60_docker_plugin_basic` en Jenkins a partir de la definición de su [Jenkinsfile](file:///home/pepesan/IdeaProjects/docker-twitchv2/compose/08_jenkins_pipeline_completo/jenkinsfile/60_docker_plugin_basic/Jenkinsfile).

### 3. Lanzar la Ejecución
Ejecuta el script de construcción:
```shell
./02_build.sh
```
Este script encolará la ejecución y se quedará esperando a que finalice.

### 4. Observar el Ciclo de Vida
Mientras la terminal muestra el mensaje `Esperando a que termine el build...`, abre la interfaz web de Jenkins (`http://localhost:8082`) y mira el panel lateral izquierdo **"Estado del ejecutor de construcciones"**:
* Verás aparecer un nodo dinámico (ej. `docker-000151cjo2u4n`) en estado "En línea".
* Al finalizar las tareas del pipeline, el nodo cambiará a estado **"En el periodo de gracia. Termina en X seg (suspendido)"**.
* Transcurridos un par de segundos, el nodo desaparecerá por completo de la pantalla.

### 5. Consultar los Logs
Una vez que el build termine en la terminal, puedes ver el volcado del log de consola completo ejecutando:
```shell
./03_check.sh
```

### 6. Limpieza del Job
Para borrar el trabajo creado de la lista de Jenkins, ejecuta:
```shell
./04_delete.sh
```
