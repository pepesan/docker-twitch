## Pasos a ejecutar

```shell
docker build -t pepesan/anaconda3-app:latest .
docker login 
docker push pepesan/anaconda3-app:latest
# ejecutar app directamente
# permisos de X
xhost +local:root
# lanzamiento de contenedor con uso de X
docker run --rm -it --env="DISPLAY" --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" pepesan/anaconda3-app:latest
```


