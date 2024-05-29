## Pasos a ejecutar

```shell
docker build -t pepesan/rockylinux:9.3 .
docker build -t pepesan/rockylinux:latest .
docker login 
docker push pepesan/rockylinux:9.3
docker push pepesan/rockylinux:latest
docker run --rm -it --name rocky pepesan/rockylinux:9.3 /bin/bash
```


