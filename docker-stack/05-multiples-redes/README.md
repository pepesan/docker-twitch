# Mismo compose diferentes redes
# Despliegue
docker stack deploy -c compose.yaml demo-redes

# App pública (routing mesh):
curl http://CUALQUIER_NODO:8083/

# DNS interno desde la app hacia DB/Redis (mismo servicio, redes distintas)
CID=$(docker ps -q -f label=com.docker.swarm.service.name=demo-redes_app | head -n1)
docker exec -it "$CID" sh -lc 'getent hosts db redis; echo OK'

