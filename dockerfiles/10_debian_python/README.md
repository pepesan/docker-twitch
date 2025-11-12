## Pasos a ejecutar

```shell
docker build -t pepesan/debian-python:13-3.14-pandas .
docker build -t pepesan/debian-python:latest .
docker login 
docker push pepesan/debian-python:13-3.14-pandas .
docker push pepesan/debian-python:latest
# ejecutar app directamente
docker run --rm -it --name debian pepesan/rockylinux-python:13-3.14-pandas .
# ejecutar shell en contenedor
docker run --rm -it --name debian pepesan/rockylinux-python:13-3.14-pandas . /bin/bash
```


