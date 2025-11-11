## Pasos a ejecutar

```shell
docker build -t pepesan/debian:trixie .
docker build -t pepesan/debian:latest .
docker login 
docker push pepesan/debian:trixie
docker push pepesan/debian:latest
docker run --rm -it --name debian pepesan/debian:trixie /bin/bash
```


