# 32_maven_deploy_nexus

Publica el `.jar` de `spring-boot-30-demo-maven` en el repositorio Maven de
Nexus (`maven-hosted`), sin tocar el `pom.xml` del proyecto: genera un
`settings.xml` con las credenciales y usa `-DaltDeploymentRepository` para
indicar el destino en la propia llamada a `mvn deploy`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

**Requiere Nexus levantado y configurado** (`./08_launch_nexus.sh` +
`./09_setup_nexus.sh` desde la carpeta principal de `compose/`).

**Nota sobre redes:** el agente Docker efímero (Maven) necesita
`--network jenkins_docker_pipeline_default` en `args` para poder resolver
el nombre `nexus` — sin esto, "No address associated with hostname".

Resultado esperado: `SUCCESS`.

## Gotcha de seguridad: `settings-nexus.xml` con la contraseña en claro

El fichero generado (`settings-nexus.xml`) lleva la contraseña de Nexus
sin cifrar. Jenkins la enmascara en el **log de consola** (`****`), pero
el **fichero en sí** quedaba en el workspace sin enmascarar — navegable
en claro desde la propia consola web (enlace "Workspaces" del build).
Arreglado con `post { always { sh 'rm -f settings-nexus.xml' } }` en la
propia stage. Verificado: tras el build, el fichero ya no está en
`/var/jenkins_home/workspace/32_maven_deploy_nexus/`.

## Dónde ver el jar publicado

Es un snapshot (`0.0.1-SNAPSHOT`), así que Nexus le añade un timestamp
distinto en cada build (`0.0.1-<timestamp>-<contador>.jar`) — hay que
buscarlo, no asumir el nombre de fichero:

```shell
curl -u admin:admin123 \
  "http://localhost:8083/service/rest/v1/search?repository=maven-hosted" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['items'][-1]['assets'][-3]['downloadUrl'])"
```

Verificado: devuelve, por ejemplo,
`http://localhost:8083/repository/maven-hosted/com/cursosdedesarrollo/demo-maven/0.0.1-SNAPSHOT/demo-maven-0.0.1-20260703.162059-1.jar`
— descarga directa con `curl -u admin:admin123 <downloadUrl>` da `HTTP 200`.
También navegable en la UI de Nexus:
`http://localhost:8083/#browse/browse:maven-hosted`.
