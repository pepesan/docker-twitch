# SeaweedFS — un solo nodo (S3 compatible)

[SeaweedFS](https://github.com/seaweedfs/seaweedfs) en modo `server`: un
único contenedor con master, volume server y filer en el mismo proceso, con
la API S3 activada. Pensado para desarrollo/pruebas — sin replicación ni
tolerancia a fallos. Para el cluster completo (3 masters + 3 volumes + 2
filers + HAProxy delante), ver
[../43_seaweedfs_cluster](../43_seaweedfs_cluster).

## Uso

```bash
cd compose/42_seaweedfs_single_node
./00_init.sh                   # (solo la primera vez) crea ./data y genera credenciales S3 nuevas
./01_launch_compose.sh         # levantar
./02_ps_compose.sh             # ver estado
./03_logs_compose.sh           # ver logs
./04_exec_compose.sh [comando] # shell dentro del contenedor (sh por defecto)
./05_stop_compose.sh           # parar (sin borrar ./data)
./06_start_compose.sh          # volver a arrancar tras un stop
./20_destroy.sh                # borrar TODO (contenedor + ./data), pide confirmación
```

## Puertos

| Puerto | Servicio                       |
|--------|---------------------------------|
| 9333   | API/UI del master               |
| 8080   | API/UI del volume server        |
| 8888   | API/UI del filer                |
| 8333   | API S3                          |

## Credenciales S3

`00_init.sh` genera `s3-config/s3.json` (identidad `pepesan`, permisos
Admin/Read/Write) a partir de `s3-config/s3.json.template`, con un
`accessKey`/`secretKey` aleatorios nuevos en cada clonado — los imprime por
pantalla al generarlos. El fichero real (`s3-config/s3.json`) NO está en
git (ver `.gitignore`); para volver a verlos: `cat s3-config/s3.json`.

## Probar con `mc` (cliente MinIO, compatible con cualquier S3)

```bash
ACCESS_KEY=$(python3 -c "import json;print(json.load(open('s3-config/s3.json'))['identities'][0]['credentials'][0]['accessKey'])")
SECRET_KEY=$(python3 -c "import json;print(json.load(open('s3-config/s3.json'))['identities'][0]['credentials'][0]['secretKey'])")

docker run --rm --network 42_seaweedfs_single_node_default \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@seaweedfs:8333" \
  quay.io/minio/mc mb sw/prueba

docker run --rm --network 42_seaweedfs_single_node_default \
  -v "$(pwd)/README.md:/tmp/f.txt" \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@seaweedfs:8333" \
  quay.io/minio/mc cp /tmp/f.txt sw/prueba/

docker run --rm --network 42_seaweedfs_single_node_default \
  -e MC_HOST_sw="http://${ACCESS_KEY}:${SECRET_KEY}@seaweedfs:8333" \
  quay.io/minio/mc ls sw/prueba
```

Desde el host (fuera de la red docker), el endpoint S3 es
`http://localhost:8333` con las mismas credenciales — válido también para
`boto3` (`boto3.client("s3", endpoint_url="http://localhost:8333", ...)`).

Verificado de extremo a extremo (creación de bucket, subida, listado y
descarga, con credenciales generadas de esta misma forma) antes de dejar
este ejemplo en el repo.
