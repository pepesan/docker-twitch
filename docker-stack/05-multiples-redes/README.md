# Mismo compose diferentes redes
# Despliegue
docker stack deploy -c compose.yaml demo-redes


## Listado de stacks
docker stack ls
## Ver servicios del stack
docker stack services demo-redes
# App pública (routing mesh):
curl http://CUALQUIER_NODO:8083/

# DNS interno desde la app hacia DB/Redis (mismo servicio, redes distintas)
CID=$(docker ps -q -f label=com.docker.swarm.service.name=demo-redes_app | head -n1)
docker exec -it "$CID" sh -lc 'getent hosts db redis; echo OK'


## Inspeccion de redes en cada nodo
docker network inspect demo-redes_public
docker network inspect demo-redes_internal



