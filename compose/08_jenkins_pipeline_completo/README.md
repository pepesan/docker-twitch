# Jenkins Controller Automatizado & Laboratorio de Docker Pipelines

Este proyecto es un laboratorio de verificación y aprendizaje end-to-end para la unidad de Jenkins CI/CD. Consiste en un stack completo de contenedores que incluye un Jenkins Controller auto-configurado, agentes fijos por SSH (con y sin Docker), un servidor Nexus OSS como gestor de artefactos y soporte nativo para aprovisionamiento de agentes en contenedores efímeros bajo demanda.

---

## Estructura de la Carpeta de Configuración (`config/`)

La carpeta `config/` contiene la definición de la infraestructura lógica de Jenkins, permitiendo que el servidor arranque sin asistente inicial y completamente listo para trabajar.

* **`config/plugins.txt`**: Lista de plugins que se instalan automáticamente mediante `jenkins-plugin-cli` durante la construcción de la imagen del Controller.
  * *Plugins clave:* `git` (control de versiones), `workflow-aggregator` (soporte para pipelines declarativos), `docker-workflow` (para usar contenedores efímeros), `configuration-as-code` (JCasC), `ssh-slaves` (conexión de agentes fijos) y `docker-plugin` (nube de contenedores dinámicos).
* **`config/casc.yaml`** (Jenkins Configuration as Code):
  * **Mensaje del sistema y ejecutores:** Define el banner de bienvenida y limita a 2 ejecutores en el Controller (built-in).
  * **Seguridad:** Configura el realm de usuarios local, creando la cuenta de administrador con credenciales parametrizables (`admin` / `admin` por defecto) y definiendo la política de accesos.
  * **Nube Docker (Docker Cloud):** Declara e inicializa la integración con el plugin de Docker local (`docker-local`). Conecta al socket de Docker del host (`unix:///var/run/docker.sock`) y define la plantilla `docker-agent-efimero` usando la imagen `jenkins/inbound-agent:alpine`. Cualquier pipeline que pida esta etiqueta levantará un contenedor dinámico que se destruirá tras finalizar el build.
* **`config/init.groovy.d/configure-agent.groovy`** (Script de inicialización Groovy):
  * Se ejecuta automáticamente en cada arranque del Controller.
  * Registra de manera programática e idempotente las credenciales de claves SSH privadas en el almacén global de Jenkins (`agent-ssh-key` y `agent2-ssh-key`).
  * Da de alta los nodos de agente permanente `agent1` y `agent2`, definiendo sus rutas de workspace, número de ejecutores y etiquetas.
* **`config/ssh/`**: Directorio donde se almacenan las claves criptográficas Ed25519 privadas y públicas generadas automáticamente para comunicar de forma segura el Controller con los agentes fijos por SSH.

---

## Scripts del Directorio Raíz

El laboratorio se gestiona por completo mediante scripts bash idempotentes (no requieren root inicialmente a menos que sea estrictamente necesario):

### Inicialización y Ciclo de Vida del Stack
* **`./00_init.sh`**: Prepara el entorno local. Crea el directorio de volumen para `jenkins_home` y genera el par de claves SSH en `./config/ssh` con permisos adecuados del usuario host, evitando conflictos de permisos de root.
* **`./01_launch.sh`**: Construye la imagen del Controller y arranca únicamente el servicio de Jenkins (sin agentes ni Nexus).
* **`./02_ps.sh`**: Atajo rápido para ver el estado actual de todos los contenedores activos en el stack.
* **`./03_logs.sh`**: Muestra los logs en vivo del Jenkins Controller para facilitar la depuración de plugins y JCasC.
* **`./100_destroy.sh`**: Detiene todos los servicios, elimina los contenedores y destruye de forma completa y segura los volúmenes locales y claves SSH.

### Orquestación de Agentes y Servicios Opcionales
* **`./04_launch_agent.sh`**: Levanta el contenedor del primer agente fijo (`agent1`), que no tiene Docker instalado.
* **`./05_check_agent.sh`**: Consulta la API de Jenkins para verificar que el nodo `agent1` se encuentra en línea.
* **`./06_launch_agent_docker.sh`**: Levanta el segundo agente fijo (`agent2`), el cual cuenta con Docker CLI interno conectado al host.
* **`./07_check_agent_docker.sh`**: Comprueba que el nodo `agent2` se encuentra activo y conectado a Jenkins.
* **`./08_launch_nexus.sh`**: Levanta un servidor Nexus OSS que hace de registro Docker privado y repositorio Maven hosted.
* **`./09_setup_nexus.sh`**: Realiza la autoconfiguración de Nexus. Cambia la contraseña por defecto de admin, acepta la EULA, activa el realm para permitir logins de Docker, crea los repositorios `maven-hosted` y `docker-hosted`, y registra la credencial `nexus-creds` en Jenkins de forma automatizada (usando fallbacks sin `sudo` interactivo si ya fue inicializado).
* **`./99_delete_all_jobs.sh`**: Limpia rápidamente todos los trabajos creados en Jenkins (reset blando).

### Aprovisionamiento y Configuración de Nube Docker Externa (LXC)
* **`./10_create_lxc_docker_node.sh`**: Crea y configura el contenedor LXC `jenkins-external-docker` con la imagen `ubuntu-2404-ssh-template`, activando los privilegios y módulos de kernel requeridos para anidar Docker con IP fija `10.207.154.80`.
* **`./11_install_docker_lxc.sh`**: Genera certificados mTLS, instala Docker Engine dentro del contenedor LXC y expone la API de forma segura a través del puerto TCP seguro `2376` (escuchando en `0.0.0.0`).
* **`./97_destroy_lxc_docker_node.sh`**: Detiene y elimina por completo el contenedor LXC `jenkins-external-docker` creado para el laboratorio.

### Suite de Pruebas Automatizada
* **`./98_test_pipelines.sh [all | NN_nombre_ejemplo]`**: Ejecuta todas las pipelines del laboratorio de forma secuencial de principio a fin, o una en concreto.
  * Autoproveee dinámicamente las dependencias de infraestructura necesarias para cada test (ej. levanta `agent1` para la serie 20, o `nexus` para la serie 30).
  * Lanza el build y consulta la API de Jenkins mediante un script de check propio para volcar el log completo.
  * Realiza limpieza interactiva ejecutando `./05_stop_deploy.sh` de los ejemplos correspondientes al finalizar cada test (series 33, 50, 92) para no dejar contenedores huérfanos.

---

## Ejemplos Disponibles (`jenkinsfile/`)

Los ejemplos se dividen por bandas temáticas según su complejidad:

| Banda | Ejemplos | Descripción |
|---|---|---|
| **01-13** | Sintaxis y Primitivas | Hola Mundo, etapas, variables de entorno, parámetros de build, acciones `post`, condicionales `when`, paralelos, stashes, aprobación de inputs, credenciales globales y matrices de compilación. |
| **20-27** | Agentes y Docker-in-Docker | builds en agentes fijos SSH (`agent1`), contenedores efímeros con `agent { docker }` construidos sobre el built-in o `agent2`, stashes inter-agente y Docker CLI. |
| **30-33** | Repositorios con Nexus | Conectividad, empuje de imágenes Docker a Nexus, despliegue de artefactos Maven y ciclo completo build-push-deploy con Compose. |
| **40-46** | Testing y Seguridad | Pruebas JUnit, métricas de cobertura JaCoCo, tests unitarios vs integración de Spring Boot, tests de Node.js en Vitest, pruebas E2E multi-navegador con Playwright y escaneos Trivy en paralelo. |
| **50-53** | Estrategias de Despliegue | Despliegue idempotente con `docker run`, despliegues multicontenedor con DB mediante Docker Compose, gestión multi-entorno (`staging`/`prod`) y rollbacks dinámicos en caso de fallo. |
| **60-69** | Integración Docker Plugin | Ejemplos que demuestran la ejecución de builds en **agentes efímeros dynamically provisioned** en la nube de Docker local (`docker-agent-efimero`, ej. `60`) y nube externa LXC (`docker-agent-externo`, ej. `61`). |
| **90-92** | Escenarios Reales | Checkout de repositorios privados GitLab con credenciales seguras, ciclo completo del backend real Spring Boot y frontend real Astro. |

---

## Lecciones Técnicas Aprendidas (Gotchas)

1. **Persistencia de `init.groovy.d/*.groovy`**: Los scripts de inicialización Groovy de referencia solo se copian a `jenkins_home` la primera vez que se monta el volumen. Cambios posteriores en este script no tendrán efecto en caliente a menos que se limpie el volumen con `./100_destroy.sh` o se copien manualmente al contenedor.
2. **Nombres de archivo Groovy con guiones**: Un script Groovy con guiones en su nombre de archivo (`configure-agent.groovy`) no debe declarar métodos con nombre (ej. `def metodo() {}`), ya que genera un ClassFormatError interno en Groovy. En su lugar se utilizan **closures** (`def metodo = { ... }`).
3. **Aislamiento de red para agentes efímeros**: Los contenedores levantados al vuelo por Jenkins vía `agent { docker { ... } }` arrancan por defecto en la red bridge estándar de Docker y no ven el resto de servicios de Compose. Es obligatorio pasar la red en los argumentos: `args '--network jenkins_docker_pipeline_default'`.
4. **Permisos del socket de Docker**: Los agentes que usan Docker CLI deben añadir al usuario `jenkins` en el grupo que posea el GID del `/var/run/docker.sock` del host, el cual puede cambiar entre distintas distribuciones de Linux.

---

## Configuración Manual de una Nube Docker Externa en la UI

Si deseas registrar manualmente un servidor Docker remoto/externo (como el contenedor LXC provisto por el script `10_create_lxc_docker_node.sh`) utilizando la interfaz de Jenkins, sigue estos pasos:

1. **Obtener la IP del host Docker externo:**
   * Ejecuta en tu terminal: `lxc list jenkins-external-docker` (normalmente asignada de forma fija como `10.207.154.80`).
2. **Acceder a la gestión de nubes en Jenkins:**
   * Entra a `http://localhost:8082` con credenciales `admin:admin`.
   * Ve a **Administrar Jenkins (Manage Jenkins) > Clouds (Nubes)**.
3. **Crear la nube de Docker externa:**
   * Haz clic en **New Cloud (Nueva nube)**.
   * Asigna el nombre **`docker-external`** y marca el botón de radio **Docker**. Haz clic en **Create**.
4. **Detalles de la Conexión Remota:**
   * Despliega la sección **Docker Cloud details**.
   * Asegúrate de marcar la casilla **Enabled**.
   * En el campo **Docker Host URI**, escribe la URI TCP correspondiente al puerto de la API expuesto:
     `tcp://10.207.154.80:2375` (Sustituye por la IP correspondiente si usas otra distinta).
   * Haz clic en **Test Connection** para validar la comunicación por red.
5. **Configurar la plantilla de Agente Externo:**
   * Haz clic en **Docker Agent templates... > Add Docker Template**.
   * Rellena los campos:
     * **Labels:** `docker-agent-externo` (la etiqueta solicitada por el pipeline del ejemplo `61`).
     * **Enabled:** Cambiar a **Enabled** (por defecto se crea como *Disabled*).
     * **Name:** `agente-externo-lxc`.
     * **Docker Image:** `jenkins/inbound-agent:alpine` (imagen oficial).
     * **Remote File System Root:** `/home/jenkins/agent`.
     * **Usage:** *Only build jobs with label expressions matching this node*.
     * **Idle timeout (Tiempo de inactividad):** Cambiar de `10` a **`1`** minuto (para la destrucción inmediata post-build).
6. **Configurar el conector:**
   * En **Connect method**, selecciona **Attach Docker container**.
7. **Guardar:**
   * Haz clic en **Save (Guardar)**.
