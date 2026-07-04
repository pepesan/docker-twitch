# 31_docker_push_nexus

Build + push de una imagen al registro Docker de Nexus (`docker-hosted`),
con dos tags: uno de versión concreta (`BUILD_NUMBER`) y `latest`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_delete.sh   # lo borra
```

**Requiere Nexus levantado y configurado** (`./08_launch_nexus.sh` +
`./09_setup_nexus.sh` desde la carpeta principal de `compose/`, que crean
el repositorio `docker-hosted` y la credencial Jenkins `nexus-creds`).

**Nota sobre redes:** `docker build`/`push`/`login` usan `localhost:8084`
(pasan por el socket al daemon del host); el `curl` de verificación del
catálogo usa `nexus:8084` (nombre de red interna de Compose, porque corre
dentro del propio contenedor del controller) — ver detalle en el propio
Jenkinsfile.

Resultado esperado: `SUCCESS`.

## Dónde ver la imagen publicada

Vía la API v2 (Docker Registry HTTP API) del registro Docker de Nexus,
desde el host (puerto publicado `8084`):

```shell
curl -u admin:admin123 http://localhost:8084/v2/demo-app/tags/list
```

Verificado: `HTTP 200`, `{"name":"demo-app","tags":["1","2","latest"]}`.
También navegable en la UI de Nexus:
`http://localhost:8083/#browse/browse:docker-hosted:v2/demo-app`.
