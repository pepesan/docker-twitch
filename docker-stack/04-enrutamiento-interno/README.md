# Ejemplo de enrutamiento interno

## Lanzamiento
docker stack deploy -c compose.yaml demo-db
## Comprobación
docker stack ls
docker stack services demo-db
## Acceso
http://NODEIP:8082/

Usuario: appuser
Contraseña: apppass
DB: appdb
Contraseña root: root

## Dar de baja
docker stack rm demo-db
