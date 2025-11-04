# Ejemplo de uso de compose.yaml para despliegue de docker stack

## Fichero compose.yaml
Despliega el servicio de un ECHO
## Lanzamiento y actualización del stack
docker stack deploy -c compose.yaml demo-stack
## Listado de stacks
docker stack ls
## Ver servicios del stack
docker stack services demo-stack
## Ver tareas por servicio
docker stack ps demo-stack
## Ver servicio concreto
docker service ps demo-stack_mesh-test --no-trunc
## Ver los detalles de puertos
docker service inspect demo-stack_mesh-test --format '{{json .Endpoint.Ports}}'
## Ver los log de un servicio
docker service logs -f demo-stack_mesh-test
## Escalar un servicio
docker service scale demo-stack_mesh-test=5
## Rollback a la anterior versión del stack
docker service rollback demo-stack_mesh-test
## Eliminar un stack
docker stack rm demo-stack



