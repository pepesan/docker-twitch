# SeaweedFS — cluster completo (S3 compatible, alta disponibilidad)

[SeaweedFS](https://github.com/seaweedfs/seaweedfs) con topología de
cluster: 3 masters (Raft), 3 volume servers, 2 filers (metadatos en
Postgres) con la API S3 activada en cada uno, y HAProxy delante
balanceando entre los dos filers (S3 y UI del filer) y sirviendo un panel
de estadísticas. Pensado para probar alta disponibilidad/replicación —
para desarrollo/pruebas simples, más sencillo usar
[../42_seaweedfs_single_node](../42_seaweedfs_single_node) (un solo
contenedor, sin esta complejidad).

## Uso

```bash
cd compose/43_seaweedfs_cluster
./00_init.sh                        # (solo la primera vez) crea ./data y genera credenciales nuevas
./01_launch_compose.sh              # levantar todos los servicios
./02_ps_compose.sh                  # ver estado
./03_logs_compose.sh [servicio]     # ver logs (todos o de uno concreto)
./04_exec_compose.sh <servicio> [comando]   # shell dentro de un servicio (sh por defecto)
./05_stop_compose.sh [servicio ...] # parar (sin borrar contenedores/datos)
./06_start_compose.sh [servicio ...]# volver a arrancar tras un stop
./20_destroy.sh                     # borrar TODO (contenedores + ./data + credenciales), pide confirmación
```

Servicios: `master1`, `master2`, `master3`, `volume1`, `volume2`,
`volume3`, `postgres`, `filer1`, `filer2`, `haproxy`.

## Puertos

| Puerto      | Servicio                                              |
|-------------|---------------------------------------------------------|
| 9333/19333  | master1 (HTTP/gRPC)                                      |
| 9334/19334  | master2                                                  |
| 9335/19335  | master3                                                  |
| 8080/18080  | volume1                                                  |
| 8081/18081  | volume2                                                  |
| 8082/18082  | volume3                                                  |
| 8889/18889  | filer1 (directo, sin pasar por HAProxy)                  |
| 8890/18890  | filer2 (directo, sin pasar por HAProxy)                  |
| **8333**    | **API S3** (vía HAProxy, balanceada entre filer1/filer2) |
| **8888**    | **UI del filer** (vía HAProxy, con auth básica)           |
| **1936**    | Panel de estadísticas de HAProxy (con auth básica)        |

Si tienes otros compose levantados que ya usan 8080/8081/8082/8333/8888/9333
(es fácil chocar con Hadoop/Spark, MinIO, Garage, etc. de otros ejemplos de
este repo), párelos antes o edita los puertos publicados en `compose.yaml`.

## Credenciales

`00_init.sh` genera, a partir de las plantillas `*.template` (los ficheros
reales NO están en git, ver `.gitignore`), y los imprime por pantalla:

- **Postgres** (`seaweedfs` / contraseña aleatoria) — en `.env` y
  `filer-config/filer.toml` (metadatos de los filers).
- **S3** (`accessKey`/`secretKey` aleatorios, identidad `pepesan`,
  permisos Admin/Read/Write) — en `s3-config/s3.json`.
- **UI del filer** (`pepesan` / contraseña aleatoria, solo el hash queda
  guardado) y **stats de HAProxy** (`pepesan` / contraseña aleatoria) — en
  `haproxy/haproxy.cfg`. Estas dos contraseñas solo se muestran una vez al
  ejecutar `00_init.sh`; si las pierdes, borra `haproxy/haproxy.cfg` y
  vuelve a ejecutar `00_init.sh` (regenera también las demás, a menos que
  las borres selectivamente).

## Probar con `mc` (cliente MinIO, compatible con cualquier S3)

```bash
ACCESS_KEY=$(python3 -c "import json;print(json.load(open('s3-config/s3.json'))['identities'][0]['credentials'][0]['accessKey'])")
SECRET_KEY=$(python3 -c "import json;print(json.load(open('s3-config/s3.json'))['identities'][0]['credentials'][0]['secretKey'])")

# contra HAProxy (balanceando filer1/filer2), red interna docker:
docker run --rm --network 43_seaweedfs_cluster_seaweedfs \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@haproxy:8333" \
  quay.io/minio/mc mb sw/prueba

docker run --rm --network 43_seaweedfs_cluster_seaweedfs \
  -v "$(pwd)/compose.yaml:/tmp/f.txt" \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@haproxy:8333" \
  quay.io/minio/mc cp /tmp/f.txt sw/prueba/

docker run --rm --network 43_seaweedfs_cluster_seaweedfs \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@haproxy:8333" \
  quay.io/minio/mc ls sw/prueba
```

Desde el host, el endpoint S3 es `http://localhost:8333` con las mismas
credenciales — válido también para `boto3`.

Verificado de extremo a extremo (arranque de los 9 contenedores, creación
de bucket, subida, listado a través de HAProxy, y comprobación de que la
UI del filer exige autenticación) antes de dejar este ejemplo en el repo.
