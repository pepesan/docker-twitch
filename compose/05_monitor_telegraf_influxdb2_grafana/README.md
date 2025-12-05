# Ejemplo de creación de un servidor de monitorización
La idea es crear un entorno Docker Compose que sea capaz
de almancenar y visualizar datos de monitorización que nos 
envíen desde diferentes servidores
## Primeros pasos
Copia el fichero .env.example a .env
```shell
cp .env.example .env
```
Ó
```shell
./00_init.sh
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

## Crea los directorios de datos

```shell
./01_create_environment.sh
```

## Configuración del compose.yaml
Este fichero permite levantar los servicios para grafana e influxdb2
Como mucho deberemos cambiar el usuario de grafana para escribir los datos en el volumen
```shell
docker compose up influxdb2 grafana -d
```
ó
```shell
./02_launch_influxdb2.sh
```
y
```shell
./03_launch_grafana.sh
```
## URLs de acceso
### InfluxDB2
- InfluxDB: http://localhost:8086/
- login: por defecto, admin/admin1234

### Grafana
- Grafana: http://localhost:3000/
- login: por defecto, admin/admin
## Comprobaciones
Comprueba que levanta correctamente los servicios
```shell
docker compose logs -f
```
Comprueba que tienes acceso al bucket de monitor desde Load Data -> Buckets
Cuando te loguees deberás cambiar la contraseña del admin

## Configurar el servicio de telegraf.conf
Para ello necesitamos saber el grupo que posee el /var/run/docker.sock
```shell
ls -la /var/run/docker.sock
```
por ejemplo en mi caso pone:
```shell
srw-rw---- 1 root docker 0 jul 14 18:48 /var/run/docker.sock
```
Habría que saber cual es GID (identificativo del grupo) del grupo de docker
```shell
cat /etc/group | grep docker
```
En mi caso dice lo siguiente:
```shell
docker:x:984:pepesan
```
Por lo que el GID es 984. 
Habría que modificar el compose.yaml del servicio telegraf para poner:
```yaml
      user: "1001:984"
```

## Lanzamos el servicio telegraf
para ello lanzamos el servicio pero sin el -d para que nos de el log 
```shell
docker compose up telegraf
```
ó 
```shell
04_launch_telegraf.sh
```
Debería darnos una salida similar a la siguiente:
```shell
$ docker compose up telegraf
[+] Running 2/2
 ✔ Container influxdb2  Running                                                                                    0.0s 
 ✔ Container telegraf   Created                                                                                    0.4s 
Attaching to telegraf
telegraf  | 2024-07-14T18:23:26Z I! Loading config: /etc/telegraf/telegraf.conf
telegraf  | 2024-07-14T18:23:26Z W! DeprecationWarning: Option "perdevice" of plugin "inputs.docker" deprecated since version 1.18.0 and will be removed in 1.35.0: use 'perdevice_include' instead
telegraf  | 2024-07-14T18:23:26Z I! Starting Telegraf 1.31.1 brought to you by InfluxData the makers of InfluxDB
telegraf  | 2024-07-14T18:23:26Z I! Available plugins: 234 inputs, 9 aggregators, 32 processors, 26 parsers, 60 outputs, 6 secret-stores
telegraf  | 2024-07-14T18:23:26Z I! Loaded inputs: cpu disk diskio docker linux_cpu mem net netstat processes procstat swap system temp
telegraf  | 2024-07-14T18:23:26Z I! Loaded aggregators: 
telegraf  | 2024-07-14T18:23:26Z I! Loaded processors: 
telegraf  | 2024-07-14T18:23:26Z I! Loaded secretstores: 
telegraf  | 2024-07-14T18:23:26Z I! Loaded outputs: influxdb_v2
telegraf  | 2024-07-14T18:23:26Z I! Tags enabled: host=moria
telegraf  | 2024-07-14T18:23:26Z W! Deprecated inputs: 0 and 1 options
telegraf  | 2024-07-14T18:23:26Z I! [agent] Config: Interval:10s, Quiet:false, Hostname:"moria", Flush Interval:10s
telegraf  | 2024-07-14T18:23:26Z W! DeprecationWarning: Value "false" for option "ignore_protocol_stats" of plugin "inputs.net" deprecated since version 1.27.3 and will be removed in 1.36.0: use the 'inputs.nstat' plugin instead for protocol stats
```
## Comprobaciones de Telegraf
Comprobamos que no da errores.

Luego deberíamos irnos al InfluxDB2 para ver si en el bucket tenemos ya datos de monitorización.

Cuando esté todo bien hacemos Control+c y lo lanzamos de la manera normal:
```shell
docker compose up -d
```
ó
```shell
05_launch_all.sh
```

## Crear el datasource en Grafana
- Debemos irnos a Connection-> Data sources
- Pulsamos en Add new data source
- Buscamos y Seleccionamos InfluxDB
- Elegimos un Nombre
- Elegiremos en Query Language Flux
- En URL pondremos la url de acceso a influxdb2, http://influxdb2:8086 ya que accedemos con el nombre del servicio de docker compose y el puerto del contenedor original
- En Auth no seleccionamos nada de momento, o quitamos basic Auth
- En los detalles de InfluxDB es donde realmente nos autenticamos con la organización, el bucket y el token, igual a cómo lo hicimos cuando enganchamos telegraf
- Finalmente pulsamos en Save & Test
Si va todo bien deberá dar un aviso de color verde y Grafana ya tiene acceso a la bbdd del bucket de Influxdb2
## Crear el dashboard en grafana
- Desde Dashboards
- Pulsamos en New -> New dashboard
- En el apartado de Import a Dashboard es donde podemos usar un dashboard ya creado por alguien que se asocie a nuestro bucket importado desde influxdb flux\
- Por ejemplo, para el uso de Docker usaremos el ID 17020 y pulsamos en Load
- Selecciona el datasource de InfluxDB que has creado antes y pulsa en Import
- Desde el dashboard selecciona el bucket monitor
- Si queremos buscar otros dashboards que nos puedan interesar: https://grafana.com/grafana/dashboards/
##  Dashboards de grafana para nuestra configuración
- Ref: https://github.com/ManoloTech/domo
- En el caso de usar el plugin de Docker: 17020
- Para el resto del sistema: 15650
## Accediendo al Dashboard
- Desde Dashboards veremos el listado de los que hemos importado
- Pulsamos sobre uno de ellos y deberíamos verlo


## Borrado de los datos y de contenedores
```shell
./10_clean.sh
```



