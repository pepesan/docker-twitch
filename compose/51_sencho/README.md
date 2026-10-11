# Sencho: gestor web de stacks Docker Compose

Despliega [Sencho](https://github.com/Studio-Saelix/sencho) (sencho.io), un
panel web para crear, editar y operar stacks de Docker Compose. Mismo patrón
de scripts que `41_zeppelin`.

## Uso

```bash
cd compose/51_sencho
./00_init.sh              # crea ./data y ./stacks (solo la primera vez)
./01_launch_compose.sh    # levantar
./02_ps_compose.sh        # estado
./03_logs_compose.sh      # logs
./04_exec_compose.sh      # shell en el contenedor
./05_stop_compose.sh      # parar
./06_start_compose.sh     # arrancar de nuevo
./20_destroy.sh           # borrar todo (pide confirmación)
```

## Acceso

http://localhost:1852 — en el primer acceso pide **crear la cuenta de
administrador**.

## Notas

- Imagen `saelix/sencho:0.97.1` (última release publicada a 2026-10-11).
- Monta `/var/run/docker.sock`: quien accede a Sencho controla el Docker del host.
- El compose de Sencho queda **fuera** de `COMPOSE_DIR` (`./stacks`): Sencho no
  debe gestionarse a sí mismo como stack; para actualizarlo usa
  *Fleet -> Node Update* en la UI. El aviso "not detected as a managed stack"
  es el estado correcto.
- Regla 1:1 de Sencho: `./stacks` se monta en la **misma ruta absoluta** dentro
  del contenedor; por eso `compose.yaml` usa `${PWD}` y debe lanzarse desde
  este directorio.
- Datos de Sencho en `./data`.

## Stack de ejemplo: `hola-nginx`

`stacks/hola-nginx/` es un stack mínimo (nginx + una página estática) para
practicar el despliegue desde Sencho. En la UI debería aparecer en la lista
de stacks (si no, refresca): ábrelo y pulsa **Deploy**/**Up**. Después, la
página está en http://localhost:8095. Puerto 8095 para no chocar con otros
ejemplos.
