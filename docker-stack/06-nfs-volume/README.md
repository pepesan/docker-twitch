# Volumen montado via NFS
## Lanzamiento
docker stack deploy -c compose.yaml demo-nfs-web
## Comprobaciones
docker stack services demo-nfs-web
docker service ps demo-nfs-web_web
## Acceso
http://SERVER_IP:8084/
