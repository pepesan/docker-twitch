## Pasos a ejecutar

```shell
docker build -t pepesan/ubuntu:jammy .
docker build -t pepesan/ubuntu:latest .
docker login 
docker push pepesan/ubuntu:jammy
docker push pepesan/ubuntu:latest
docker run --rm -it --name ubuntu pepesan/ubuntu:jammy /bin/bash
```


