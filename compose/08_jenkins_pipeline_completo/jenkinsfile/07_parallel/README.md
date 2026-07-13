# 07_parallel

`parallel {}` ejecuta varias stages a la vez en vez de una tras otra. En la
consola se ve la salida de las tres ramas intercalada, prueba de que corren
de verdad al mismo tiempo (no en secuencia).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`.

## Dónde ver las ramas en paralelo gráficamente

La consola intercala la salida de las tres ramas, pero para verlas de
verdad como ramas paralelas (con su duración y logs por stage) está el
plugin `pipeline-graph-view` (ver `compose/README.md`, sección "Plugins
instalados"), con dos puntos de entrada distintos en el menú lateral
izquierdo según en qué página estés:

- Dentro de un build concreto (`http://localhost:8082/job/07_parallel/lastBuild/`):
  enlace **"Pipeline Overview"** → `.../lastBuild/stages`.
- En la página principal del job (`http://localhost:8082/job/07_parallel/`):
  enlace **"Stages"** → `.../multi-pipeline-graph` (vista combinada de
  varios builds, no solo el último).

Verificado: ambas rutas responden `HTTP 200`.
