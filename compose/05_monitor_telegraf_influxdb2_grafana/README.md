# Ejemplo de creación de un servidor de monitorización
La idea es crear un entorno Docker Compose que sea capaz
de almancenar y visualizar datos de monitorización que nos 
envíen desde diferentes servidores
## Primeros pasos
Copia el fichero .env.example a .env
```shell
cp .env.example .env
```
## Edita el fichero .env
### Variables de Entorno para InfluxDB2
- DOCKER_INFLUXDB_INIT_PASSWORD: contraseña del InfluxDB
- DOCKER_INFLUXDB_INIT_ORG: nombre de la organización por defecto
- DOCKER_INFLUXDB_INIT_BUCKET: nombre del bucket donde se guardará la información
- DOCKER_INFLUXDB_INIT_RETENTION: duración de los datos en el bucket, por defecto, 4w, 4 semanas
Debes generar un token para controlar el acceso root al servidor:
```shell
openssl rand 32 | xxd -ps | head -n 1 | cut -c1-32
```
- DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: aquí va el token de acceso
### Contraseña para Grafana
- GF_SECURITY_ADMIN_PASSWORD: contraseña de admin
### Datos de envío de correo SMTP
- GF_SMTP_ENABLED=true
- GF_SMTP_HOST=example.com:465
- GF_SMTP_USER=grafana_no_reply@example.com
- GF_SMTP_PASSWORD=mipasscorreo
- GF_SMTP_FROM_ADDRESS=grafana_no_reply@correo.com
- GF_SMTP_FROM_NAME=Grafana CDD

## Configuración del compose.yaml
Este fichero permite levantar los servicios para grafana e influxdb2
Como mucho deberemos cambiar el usuario de grafana para escribir los datos en el volumen
```shell
docker compose up -d
```
## URLs de acceso
- Grafana: http://localhost:3000/
- login: por defecto, admin/admin
- InfluxDB: http://localhost:8086/
- login: por defecto, admin/admin
Comprueba que tienes acceso a ambos servicios
## Comprobaciones
Comprueba que en InfluxDB2  existe el bucket monitor desde Load Data -> Buckets
Y mira a ver si hay datos que se están guardando en el bucket