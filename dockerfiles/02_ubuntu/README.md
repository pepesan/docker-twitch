## Pasos a ejecutar

```shell
docker build -t pepesan/ubuntu:noble .
docker build -t pepesan/ubuntu:latest .
docker login 
docker push pepesan/ubuntu:noble
docker push pepesan/ubuntu:latest
docker run --rm -it --name ubuntu pepesan/ubuntu:noble /bin/bash
```


