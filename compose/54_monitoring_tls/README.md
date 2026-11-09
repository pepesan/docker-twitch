# Monitorización local con HTTPS y mTLS

Variante TLS del ejemplo [`53_monitoring`](../53_monitoring/README.md). Reutiliza sus servicios/configuración base y aplica `compose.tls.yaml`, que añade Caddy como proxy TLS y requiere certificado cliente para acceder a Grafana. Solo el gateway publica `127.0.0.1:3300`; conserva además el login de Grafana. No habilita acceso remoto.

Los archivos de este directorio incluyen el override TLS, el Caddyfile y scripts. La configuración de Alloy, Prometheus, Loki y Grafana vive en `../53_monitoring/`. Los certificados de laboratorio quedan en `certs/`, excluidos por Git; no uses sus claves en producción.

## Paso a paso

Ejecuta en orden desde esta carpeta:

1. `./00_init.sh` — inicializa las variables/datos comunes mediante `../53_monitoring/00_init.sh` y genera una CA, certificado de servidor y certificado cliente de laboratorio si no existen.
2. `./01_launch_compose.sh` — valida el Compose combinado y arranca servicios con HTTPS/mTLS.
3. `./02_ps_compose.sh` — muestra estado; abre <https://localhost:3300> usando el certificado cliente y luego inicia sesión en Grafana.
4. `./03_logs_compose.sh [servicio]` — sigue los logs generales o de un servicio; Ctrl-C para salir.
5. `./04_exec_compose.sh SERVICIO COMANDO...` — ejecuta un comando en el servicio, por ejemplo `./04_exec_compose.sh prometheus promtool --version`.
6. `./05_stop_compose.sh` — detiene sin borrar datos.
7. `./06_start_compose.sh` — reanuda contenedores detenidos.
8. `./99_destroy.sh` — solicita escribir `DESTROY`; elimina contenedores, red, volúmenes, datos locales y llaves/certificados de laboratorio.

No ejecutes los ejemplos 53 y 54 simultáneamente: comparten el proyecto, servicios y puerto. El `99_destroy.sh` de esta variante borra también `../53_monitoring/.env` y `../53_monitoring/data/alloy`; para desplegar de nuevo, vuelve al paso 1.

## Comprobar mTLS

El certificado cliente lo genera el paso 1. Desde esta carpeta, verifica acceso con cliente:

```sh
curl --fail --cacert certs/ca.crt --cert certs/client.crt --key certs/client.key \
  https://localhost:3300/api/health
```

La petición sin certificado cliente debe fallar durante el handshake. La clave privada de CA y las demás llaves son locales e ignoradas por Git; no las envíes ni las reutilices.

## Acceso remoto

No se publica acceso remoto. Si se requiere, debe aprobarse por separado: HTTPS en una interfaz/firewall autorizados, mTLS con certificados emitidos y rotados por el PKI aprobado, y Grafana/Prometheus/Loki sin puertos directos al exterior. No hay claves reales versionadas ni valores para un entorno de producción.
