## Pasos a ejecutar

```shell
docker build -t pepesan/debian:bookworm .
docker build -t pepesan/debian:latest .
docker login 
docker push pepesan/debian:bookworm
docker push pepesan/debian:latest
docker run --rm -it --name debian pepesan/debian:bookworm /bin/bash
```


