# Jenkins Controller Automatizado & Laboratorio de Docker Pipelines

Este proyecto es un laboratorio de verificación y aprendizaje end-to-end para la unidad de Jenkins CI/CD. Consiste en un stack completo de contenedores que incluye un Jenkins Controller auto-configurado, agentes fijos por SSH (con y sin Docker), un servidor Nexus OSS como gestor de artefactos y soporte nativo para aprovisionamiento de agentes en contenedores efímeros bajo demanda.

---

## Servicios de Docker Compose

| Servicio | Perfil | Función | Puertos publicados | Script de arranque |
|---|---|---|---|---|
| `jenkins_controller` | Predeterminado | Controller Jenkins y Docker Cloud local | `8082` (web), `50001` (agentes) | `./01_launch.sh` |
| `jenkins_agent` | `agent` | Agente SSH fijo sin Docker | Ninguno; expone `22` solo en Compose | `./04_launch_agent.sh` |
| `jenkins_agent_docker` | `agent-docker` | Agente SSH fijo con Docker CLI y socket del host | Ninguno; expone `22` solo en Compose | `./06_launch_agent_docker.sh` |
| `nexus` | `nexus` | Repositorio Maven y registro Docker privado | `8083` (UI/API), `8084` (registro) | `./08_launch_nexus.sh` |
| `sonarqube` | `sonar` | Servidor de análisis estático SonarQube | `9005` (web/API) | `./12_launch_sonar.sh` |

Los agentes efímeros `docker-agent-efimero` y `docker-agent-externo` no son servicios de Compose: Jenkins los crea bajo demanda mediante Docker Plugin. El segundo se ejecuta en el nodo LXC externo preparado con `./10_create_lxc_docker_node.sh` y `./11_install_docker_lxc.sh`.

---

## Estructura de la Carpeta de Configuración (`config/`)

La carpeta `config/` contiene la definición de la infraestructura lógica de Jenkins, permitiendo que el servidor arranque sin asistente inicial y completamente listo para trabajar.

* **`config/plugins.txt`**: Lista de plugins que se instalan automáticamente mediante `jenkins-plugin-cli` durante la construcción de la imagen del Controller.
  * *Plugins clave:* `git` (control de versiones), `workflow-aggregator` (soporte para pipelines declarativos), `docker-workflow` (para usar contenedores efímeros), `configuration-as-code` (JCasC), `ssh-slaves` (conexión de agentes fijos) y `docker-plugin` (nube de contenedores dinámicos).
* **`config/casc.yaml`** (Jenkins Configuration as Code):
  * **Mensaje del sistema y ejecutores:** Define el banner de bienvenida y limita a 2 ejecutores en el Controller (built-in).
  * **Seguridad:** Configura el realm de usuarios local, creando la cuenta de administrador con credenciales parametrizables (`admin` / `admin` por defecto) y definiendo la política de accesos.
  * **Nube Docker local:** Declara `docker-local`, conecta al socket del host (`unix:///var/run/docker.sock`) y define la plantilla `docker-agent-efimero`.
  * **Nube Docker externa:** Declara `docker-external`, conecta mediante mTLS a `tcp://10.207.154.80:2376` y define la plantilla `docker-agent-externo` utilizada por el ejemplo 61.
  * Ambas plantillas usan `jenkins/inbound-agent:alpine` y eliminan el contenedor efímero después del build.
* **`config/init.groovy.d/configure-agent.groovy`** (Script de inicialización Groovy):
  * Se ejecuta automáticamente en cada arranque del Controller.
  * Registra de manera programática e idempotente las credenciales de claves SSH privadas en el almacén global de Jenkins (`agent-ssh-key` y `agent2-ssh-key`).
  * Da de alta los nodos de agente permanente `agent1` y `agent2`, definiendo sus rutas de workspace, número de ejecutores y etiquetas.
* **`config/ssh/`**: Directorio donde se almacenan las claves criptográficas Ed25519 privadas y públicas generadas automáticamente para comunicar de forma segura el Controller con los agentes fijos por SSH.
* **`config/certs/`**: Certificados y claves mTLS para la nube Docker externa. Se monta en modo lectura dentro del Controller y está excluido de Git porque contiene claves privadas.

---

## Scripts del Directorio Raíz

El laboratorio se gestiona por completo mediante scripts bash idempotentes (no requieren root inicialmente a menos que sea estrictamente necesario):

### Inicialización y Ciclo de Vida del Stack
* **`./00_init.sh`**: Prepara los directorios locales de `jenkins_home`, SSH y certificados. En una instalación limpia genera certificados provisionales para que JCasC pueda cargar; el script `11_install_docker_lxc.sh` los sustituye por certificados mTLS reales cuando se prepara la nube externa.
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
* **`./12_launch_sonar.sh`**: Levanta un servidor SonarQube para análisis estático de código.
* **`./13_setup_sonar.sh`**: Realiza la autoconfiguración de SonarQube. Espera a que esté listo, cambia la contraseña por defecto de admin, genera el token de análisis y lo registra en Jenkins de forma automatizada.
* **`./99_delete_all_jobs.sh`**: Limpia rápidamente todos los trabajos creados en Jenkins (reset blando).

### Datos de Conexión a Nexus y SonarQube

Ejecuta primero los scripts de lanzamiento (`./08_launch_nexus.sh` o `./12_launch_sonar.sh`) y después sus correspondientes scripts de configuración (`./09_setup_nexus.sh` o `./13_setup_sonar.sh`).

| Uso | Dirección |
|---|---|
| Interfaz web y API de Nexus desde el host | `http://localhost:8083` |
| Repositorio Maven hosted desde el host | `http://localhost:8083/repository/maven-hosted/` |
| Registro Docker de Nexus desde el host | `localhost:8084` |
| Interfaz web de SonarQube desde el host | `http://localhost:9005` |
| Interfaz, API y Maven de Nexus desde la red de Compose | `http://nexus:8081` |
| Registro Docker de Nexus desde la red de Compose | `nexus:8084` |
| Interfaz web y API de SonarQube desde la red de Compose | `http://sonarqube:9000` |

Las credenciales predeterminadas son `admin` / `admin123` (tanto para Nexus como para SonarQube).
* **Nexus**: La contraseña se puede configurar definiendo la variable de entorno `NEXUS_ADMIN_PASSWORD` y se guarda en Jenkins bajo el ID `nexus-creds` (tipo Username/Password).
* **SonarQube**: La contraseña de administración se puede configurar mediante `SONAR_ADMIN_PASSWORD` y Jenkins almacena el token de análisis generado bajo el ID `sonar-token` (tipo Secret Text).

Ejemplo de acceso al registro Docker:

```shell
docker login localhost:8084 -u admin -p admin123
```

### Aprovisionamiento y Configuración de Nube Docker Externa (LXC)
* **`./10_create_lxc_docker_node.sh`**: Crea y configura el contenedor LXC `jenkins-external-docker` con la imagen `ubuntu-2404-ssh-template`, activando los privilegios y módulos de kernel requeridos para anidar Docker con IP fija `10.207.154.80`.
* **`./11_install_docker_lxc.sh`**: Instala y configura Docker Engine dentro del LXC, gestiona certificados mTLS reutilizables, expone la API segura en `2376`, verifica la conexión y recarga Jenkins cuando sea necesario.
* **`./97_destroy_lxc_docker_node.sh`**: Detiene y elimina por completo el contenedor LXC `jenkins-external-docker` creado para el laboratorio.

#### 📦 Pila de Software y Configuración del Nodo LXC Remoto

El contenedor LXC `jenkins-external-docker` (IP `10.207.154.80`) actúa como nuestro host de producción/despliegue remoto. Para poder ser gestionado desde Jenkins mediante Docker nativo, SSH y Ansible, el script `./11_install_docker_lxc.sh` le instala y configura la siguiente pila de componentes:

1. **Motor de Docker (`docker-ce`, `docker-ce-cli`, `containerd.io`)**: El motor de contenedores base para ejecutar las aplicaciones.
2. **Docker Compose Plugin (`docker-compose-plugin`)**: Habilita la sintaxis nativa de Docker Compose (utilizado en los despliegues de los ejemplos `55` y `57`).
3. **API Expuesta por TLS (`tcp://0.0.0.0:2376`)**:
   * Se configura mediante `/etc/docker/daemon.json` forzando autenticación mutua TLS (`tlsverify: true`).
   * Se copian los certificados del servidor (`ca.pem`, `server-cert.pem`, `server-key.pem`) en `/etc/docker/` generados dinámicamente en el host.
   * Se añade un override de systemd en `/etc/systemd/system/docker.service.d/override.conf` para arrancar el demonio escuchando tanto en el socket de UNIX local como en el puerto TCP `2376`.
4. **Acceso SSH sin Contraseña**:
   * El servicio `openssh-server` viene preconfigurado en la imagen base.
   * Se inyecta automáticamente la clave pública generada para Jenkins (`config/ssh/id_ed25519.pub`) en `/root/.ssh/authorized_keys` del contenedor LXC para permitir conexiones automatizadas y seguras de SSH.
5. **Biblioteca de Docker para Python (`python3-docker`)**:
   * Instalada vía `apt` dentro del LXC.
   * Es una **dependencia crítica** requerida por la colección `community.docker` de Ansible para que el módulo `community.docker.docker_container` (ejemplo `56`) pueda interactuar con el demonio local de Docker a través de Python.

#### Ejemplo 61: Agente Docker Efímero Externo

El ejemplo `61_docker_plugin_external` ejecuta el build en un contenedor efímero creado en el motor Docker del LXC, no en el host del Controller:

```text
Pipeline (label: docker-agent-externo)
               |
               v
Jenkins Controller -- mTLS :2376 --> Docker Engine en LXC
                                             |
                                             v
                              jenkins/inbound-agent:alpine
```

| Elemento | Valor |
|---|---|
| Nombre del LXC | `jenkins-external-docker` |
| IP fija | `10.207.154.80` |
| Endpoint Docker | `tcp://10.207.154.80:2376` |
| Seguridad | TLS mutuo con CA local |
| Nube configurada en Jenkins | `docker-external` |
| Credencial Jenkins | `docker-external-tls-creds` |
| Etiqueta solicitada por el pipeline | `docker-agent-externo` |
| Imagen del agente | `jenkins/inbound-agent:alpine` |
| Método de conexión | Docker `attach` |

Requisitos del host:

* LXD/LXC operativo y accesible mediante el comando `lxc`.
* Imagen local `ubuntu-2404-ssh-template` disponible para crear el nodo.
* Docker, OpenSSL y curl instalados en el host.
* Acceso desde la red del Controller a `10.207.154.80:2376`.

##### Ejecución Automática Desde Cero

La forma recomendada es utilizar la suite, que prepara todas las dependencias antes de crear el job:

```shell
./00_init.sh
./98_test_pipelines.sh 61
```

Para este ejemplo la suite realiza, en orden:

1. Crea o arranca el LXC mediante `10_create_lxc_docker_node.sh`.
2. Instala o valida Docker mediante `11_install_docker_lxc.sh`.
3. Genera certificados mTLS si no existen, están incompletos, han caducado o caducarán en menos de 24 horas.
4. Copia al LXC el certificado del servidor y configura Docker en `2376` con verificación obligatoria del cliente.
5. Comprueba `https://10.207.154.80:2376/_ping` usando el certificado del Controller.
6. Si Jenkins ya estaba ejecutándose, lo reinicia y espera a que vuelva a responder para recargar `docker-external-tls-creds`.
7. Si Jenkins todavía no estaba iniciado, lo arranca después de disponer de los certificados reales.
8. Crea el job, ejecuta el pipeline, comprueba el resultado y elimina el job de prueba.

Resultado esperado:

```text
Resultado: SUCCESS
>>> [OK] Test de '61_docker_plugin_external' finalizado.
```

##### Preparación Manual

Si se prefiere ejecutar cada paso por separado:

```shell
./00_init.sh
./10_create_lxc_docker_node.sh
./11_install_docker_lxc.sh
./01_launch.sh # solo si Jenkins aún no está arrancado

./jenkinsfile/61_docker_plugin_external/01_create.sh
./jenkinsfile/61_docker_plugin_external/02_build.sh
./jenkinsfile/61_docker_plugin_external/03_check.sh
./jenkinsfile/61_docker_plugin_external/04_delete.sh
```

`10_create_lxc_docker_node.sh` y `11_install_docker_lxc.sh` son idempotentes y pueden repetirse. Los certificados se guardan localmente en `config/certs/` y están excluidos de Git porque contienen claves privadas. `00_init.sh` puede crear certificados provisionales para que JCasC arranque en una instalación limpia; `11_install_docker_lxc.sh` los sustituye por el conjunto real completo antes de utilizar la nube externa.

##### Comprobaciones y Diagnóstico

Estado e IP del LXC:

```shell
lxc list jenkins-external-docker
```

Estado de Docker y puerto TLS dentro del LXC:

```shell
lxc exec jenkins-external-docker -- systemctl is-active docker.service
lxc exec jenkins-external-docker -- ss -lntp
```

Prueba mTLS directa desde el host:

```shell
curl --cert config/certs/cert.pem \
  --key config/certs/key.pem \
  --cacert config/certs/ca.pem \
  https://10.207.154.80:2376/_ping
```

La respuesta esperada es `OK`.

| Síntoma | Causa probable | Acción |
|---|---|---|
| `All nodes of label 'docker-agent-externo' are offline` | Jenkins no puede usar la nube externa | Ejecutar `./11_install_docker_lxc.sh` y volver a lanzar el build |
| `No route to host` | LXC detenido, IP distinta o ruta de red ausente | Comprobar `lxc list` y que la IP sea `10.207.154.80` |
| `Connection refused` | Docker no escucha en `2376` | Revisar `systemctl status docker` y `/etc/docker/daemon.json` dentro del LXC |
| `PKIX path building failed` | Jenkins conserva una CA anterior | Repetir `./11_install_docker_lxc.sh`; el script reinicia Jenkins y recarga la credencial |
| `certificate_unknown` | Certificados cliente/servidor firmados por CA distintas | Repetir la preparación para sincronizar los PEM del host y del LXC |
| El build queda esperando indefinidamente | La plantilla no puede aprovisionar el agente | Revisar `docker logs jenkins_docker_pipeline` y la nube `docker-external` en Jenkins |

Para eliminar únicamente la infraestructura externa:

```shell
./97_destroy_lxc_docker_node.sh
```

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
| **40-47** | Testing, Seguridad y Calidad | Pruebas JUnit, métricas de cobertura JaCoCo, análisis estático con SonarQube, tests unitarios vs integración de Spring Boot, tests de Node.js en Vitest, pruebas E2E multi-navegador con Playwright y escaneos Trivy en paralelo. |
| **50-58** | Estrategias de Despliegue | Despliegue idempotente con `docker run`, despliegues multicontenedor con DB mediante Docker Compose, gestión multi-entorno (`staging`/`prod`), rollbacks dinámicos, y despliegues en el servidor LXC externo vía SSH, Ansible (tanto individuales como con Docker Compose) y a nivel de API Docker nativa sobre TLS, usando credenciales secretas enmascaradas. |
| **60-69** | Integración Docker Plugin | Ejemplos que demuestran la ejecución de builds en **agentes efímeros dynamically provisioned** en la nube de Docker local (`docker-agent-efimero`, ej. `60`) y nube externa LXC (`docker-agent-externo`, ej. `61`). |
| **90-92** | Escenarios Reales | Checkout de repositorios privados GitLab con credenciales seguras, ciclo completo del backend real Spring Boot y frontend real Astro. |

---

## Lecciones Técnicas Aprendidas (Gotchas)

1. **Persistencia de `init.groovy.d/*.groovy`**: Los scripts de inicialización Groovy de referencia solo se copian a `jenkins_home` la primera vez que se monta el volumen. Cambios posteriores en este script no tendrán efecto en caliente a menos que se limpie el volumen con `./100_destroy.sh` o se copien manualmente al contenedor.
2. **Nombres de archivo Groovy con guiones**: Un script Groovy con guiones en su nombre de archivo (`configure-agent.groovy`) no debe declarar métodos con nombre (ej. `def metodo() {}`), ya que genera un ClassFormatError interno en Groovy. En su lugar se utilizan **closures** (`def metodo = { ... }`).
3. **Aislamiento de red para agentes efímeros**: Los contenedores levantados al vuelo por Jenkins vía `agent { docker { ... } }` arrancan por defecto en la red bridge estándar de Docker y no ven el resto de servicios de Compose. Es obligatorio pasar la red en los argumentos: `args '--network jenkins_docker_pipeline_default'`.
4. **Permisos del socket de Docker**: Los agentes que usan Docker CLI deben añadir al usuario `jenkins` en el grupo que posea el GID del `/var/run/docker.sock` del host, el cual puede cambiar entre distintas distribuciones de Linux.
5. **Content Security Policy (CSP) y reportes HTML (Playwright/Allure)**: Por defecto, Jenkins aplica una directiva CSP sumamente restrictiva (`hudson.model.DirectoryBrowserSupport.CSP`) que bloquea la ejecución de scripts (JS) y estilos en línea (CSS) en los artefactos HTML archivados para evitar ataques XSS (Cross-Site Scripting). Como consecuencia, reportes modernos e interactivos como los de Playwright (Ejemplo 45) o Allure se cargan vacíos o sin estilos. En este laboratorio hemos desactivado la CSP pasándole una cadena vacía en las `JAVA_OPTS` del `Dockerfile`. **Importante en Producción:** Deshabilitar la CSP por completo supone un riesgo crítico de seguridad si usuarios malintencionados tienen capacidad de subir HTML/JS arbitrario. En producción, se debe relajar la política con un perfil restrictivo pero funcional (ej. `sandbox allow-scripts; default-src 'self'; style-src 'self' 'unsafe-inline';`) o delegar la visualización a un servidor externo.

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
     `tcp://10.207.154.80:2376` (Sustituye por la IP correspondiente si usas otra distinta).
   * Selecciona la credencial TLS **`docker-external-tls-creds`**.
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
