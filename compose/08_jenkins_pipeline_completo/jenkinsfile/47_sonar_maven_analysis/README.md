# 47_sonar_maven_analysis

Realiza el análisis estático de código de la aplicación `spring-boot-30-demo-maven` en SonarQube. Genera métricas de calidad de código, vulnerabilidades, code smells y duplicaciones de forma automática sin modificar el `pom.xml` del proyecto.

## Cómo probarlo

1. **Asegúrate de levantar SonarQube y configurarlo**:
   ```shell
   # Desde el directorio raíz compose/08_jenkins_pipeline_completo/
   ./12_launch_sonar.sh   # Levanta SonarQube en el puerto 9005 (evita colisiones con Portainer)
   ./13_setup_sonar.sh    # Espera a que se inicie, cambia la clave predeterminada de admin y registra el token en Jenkins
   ```

2. **Ejecuta el ejemplo**:
   ```shell
   ./01_create.sh   # da de alta (o actualiza) el job en Jenkins
   ./02_build.sh    # lo lanza y espera el resultado
   ./03_check.sh    # consulta el estado y log completo del último build
   ./04_delete.sh    # lo borra
   ```

## Requisitos de Red y Gotchas Clave

* **Red compartida**: El agente efímero de Maven necesita conectarse a la red `--network jenkins_docker_pipeline_default` para resolver el host de SonarQube por nombre de servicio (`http://sonarqube:9000`).
* **Elasticsearch y vm.max_map_count**: SonarQube utiliza un Elasticsearch embebido. Si el contenedor se detiene nada más arrancar, se debe a que la directiva de mapas de memoria del kernel de Linux es insuficiente. Se soluciona ejecutando temporalmente en el host:
  ```shell
  sudo sysctl -w vm.max_map_count=262144
  ```

## Dónde ver el análisis

Una vez finalizado el build correctamente (`SUCCESS`):

* **En la UI de SonarQube**: Accede a [http://localhost:9005/](http://localhost:9005/) con credenciales `admin` / `admin123`. Verás el proyecto `demo-maven` con todas las métricas de cobertura de código, bugs, vulnerabilidades y hotspots de seguridad.
