# Docker Compose profiles

Ejemplo mínimo de cómo marcar un servicio como opcional con `profiles:`.
`web` se levanta siempre; `monitor` solo si se activa el perfil `monitoring`.

## Scripts

```shell
./00_init.sh    # nada que preparar en este ejemplo (sin volúmenes)
./01_launch.sh  # levanta el servicio por defecto (web)
./02_ps.sh      # estado de los contenedores
./03_logs.sh    # logs en vivo (acepta un servicio: ./03_logs.sh monitor)
./10_destroy.sh # para y elimina los contenedores (incluye el perfil monitoring)
```

## Arrancar solo el servicio por defecto

```shell
docker compose up -d
docker compose ps
```

Solo aparece `web`.

## Arrancar también el servicio opcional

```shell
docker compose --profile monitoring up -d
docker compose ps
```

Ahora aparecen `web` y `monitor`.

## Arrancar, parar o borrar un servicio concreto por nombre

`up`, `stop` y `down` aceptan el nombre del servicio como argumento, para
actuar solo sobre ese servicio en vez de sobre todo el stack:

```shell
docker compose up -d web       # (re)arranca solo "web"
docker compose stop monitor    # para solo "monitor", sin borrar el contenedor
docker compose down monitor    # para y borra solo el contenedor de "monitor"
```

## Limpieza

```shell
./10_destroy.sh
```

Importante: si arrancaste `monitor` con `--profile monitoring`, un
`docker compose down` normal (sin el flag) no lo ve y lo deja parado sin
borrar. Por eso `10_destroy.sh` repite `--profile monitoring` al limpiar.
