# Ejemplo sencillo de servicio Nginx 

Ejemplo de servicio Docker compose para arrancar un servidor nginx 
en el puerto 81 local y el puerto 80 del contenedor

## Arranque
```shell
docker compose up -d
```
## Acceso web
```shell
curl http://localhost:81
```
# Parada
```shell
docker compose down
```
