# 11_archive_artifacts

`archiveArtifacts` guarda ficheros junto al build en Jenkins (descargables
desde la UI/API), con `fingerprint: true` para poder rastrearlos entre
builds, sin necesidad de un repositorio externo.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`.

## Dónde ver el artefacto

Descargable directamente desde la API de Jenkins:

```shell
curl -u admin:admin http://localhost:8082/job/11_archive_artifacts/lastBuild/artifact/resultado.txt
```

Verificado: `HTTP 200`. También navegable en
`http://localhost:8082/job/11_archive_artifacts/<build>/artifact/resultado.txt`
o listable con
`curl -u admin:admin ".../lastBuild/api/json?tree=artifacts[fileName,relativePath]"`
(usar `-g` en curl para que no interprete los `[]` como globbing).
