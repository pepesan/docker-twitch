# Ejemplo de uso de compose.yaml para despliegue de docker stack

## Fichero compose.yaml
Despliega el servicio de un ECHO
## Lanzamiento y actualización del stack
docker stack deploy -c compose.yaml demo-web
## Listado de stacks
docker stack ls
## Ver servicios del stack
docker stack services demo-web
## Ver tareas por servicio
docker stack ps demo-web
## Ver servicio concreto
docker service ps demo-web_web --no-trunc
## Ver los detalles de puertos
docker service inspect demo-web_web --format '{{json .Endpoint.Ports}}'
## Ver los log de un servicio
docker service logs -f demo-web_web
## Escalar un servicio
docker service scale demo-web_web=5
## Rollback a la anterior versión del stack
docker service rollback demo-web_web
## Eliminar un stack
docker stack rm demo-web



