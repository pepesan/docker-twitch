# Ejemplo sencillo de un servicio Wordpress con BBDD Mariadb

Ejemplo de servicio Docker compose para arrancar un servidor con Wordpress
en el puerto 81 local y el puerto 80 del contenedor
Que haga uso de un servidor de bbdd Mariadb 

## Permisos
Para que no de problemas el arranque de la bbdd por tema de permisos debemos
crear las carpetas volumes/database y ponerle los permisos adecuados
```shell
mkdir -p volumes
mkdir -p volumes/database
mkdir -p volumes/html
chmod -R 777 volumes/
```
## Arranque
```shell
docker compose up -d
```
## Acceso web
URL: http://localhost:81
```shell
curl http://localhost:81
```

# Parada
```shell
docker compose down
```
## Limpieza
```shell
sudo rm -rf volumes/database/* volumes/html/*
```
