# MariaDB endurecido con Dockerfile

Ejemplo local de construcción de una imagen MariaDB endurecida, siguiendo el flujo numerado de `dockerfiles/28_debian_fastapi_app_uv`. Se usa MariaDB Community Server 11.8.9 (LTS) sobre la imagen oficial Ubuntu 24.04 con digest fijado. El Dockerfile actualiza los paquetes Ubuntu con parches disponibles y sustituye `gosu` por una compilación del release 1.20 con Go 1.27.3 y `golang.org/x/sys` actualizado: el escaneo de la base inicial encontró vulnerabilidades altas/críticas en APT y en el Go embebido de gosu.

**Esta imagen no está libre de todas las vulnerabilidades conocidas.** Con Trivy 0.76.1 y su base de datos local del 2026-11-09, el escaneo completo de la imagen construida encontró 17 CVE restantes: 10 MEDIUM y 7 LOW, sin HIGH/CRITICAL. El informe no ofrece versión corregida para esos hallazgos de paquetes Ubuntu. `01_scan_image.sh` impone el gate de cero HIGH/CRITICAL; no disfraza las demás severidades. Si tu política exige cero CVE de cualquier severidad, este resultado no cumple todavía. Los resultados cambian con nuevas publicaciones y bases de datos: vuelve a escanear y reconstruir periódicamente.

La configuración deshabilita `LOCAL INFILE`, restringe importación/exportación de ficheros del servidor, desactiva resolución DNS de clientes y enlaces simbólicos. En ejecución el rootfs es de solo lectura; la base va en un volumen Docker y las contraseñas se montan desde ficheros ignorados. El puerto 3306 solo se publica en loopback como `127.0.0.1:3307`. El contenedor elimina todas las capacidades y añade únicamente `CHOWN`, `SETUID`, `SETGID` y `DAC_READ_SEARCH` requeridas por el entrypoint oficial para preparar datos, cambiar al usuario mysql y leer secretos locales.

## Requisitos

- Docker Engine y CLI.
- Trivy instalado para ejecutar el gate de vulnerabilidades: <https://trivy.dev/latest/getting-started/installation/>.
- OpenSSL para generar contraseñas locales.

## Paso a paso

Desde `dockerfiles/29_mariadb_hardened`:

1. Construye la imagen: `./00_create_image.sh` (`docker-twitch-mariadb-hardened:11.8.9-1`). El Dockerfile fija los digests de MariaDB y Go y compila gosu desde un commit concreto.
2. Escanea antes de ejecutar: `./01_scan_image.sh`. El script devuelve error si Trivy encuentra CVEs HIGH/CRITICAL; no continúes si falla.
3. Crea credenciales aleatorias en `secrets/`: `./02_init_secrets.sh`. No imprime las contraseñas; ambos ficheros están excluidos de Git y tienen modo `0600`.
4. Arranca: `./03_launch_container.sh`. Usa un volumen persistente, secretos de solo lectura, rootfs read-only, tmpfs restringidos, `no-new-privileges`, límite de procesos y publicación solo en loopback.
5. Comprueba el estado, el healthcheck y las opciones SQL: `./04_check_container.sh`.
6. Conecta como usuario de aplicación (solicita la contraseña): `./05_connect_container.sh`.
7. Sigue logs: `./06_log_container.sh` (Ctrl-C termina el seguimiento).
8. Detén conservando datos: `./07_stop_container.sh`.
9. Para borrar definitivamente contenedor, volumen y secretos, ejecuta `./08_delete_container.sh` y confirma escribiendo `DESTROY`.

Para reconstruir con parches nuevos, actualiza el digest/tag de MariaDB y el Go/Gosu fijados en `Dockerfile`, vuelve a ejecutar los pasos 1–2 y despliega el resultado probado. Los datos existentes no se migran automáticamente entre versiones mayores; haz backup y sigue la guía oficial de actualización de MariaDB.

No hay script de push: la imagen queda local. Publicar requiere una revisión de seguridad adicional, etiquetado de release y autenticación explícita en el registro.
