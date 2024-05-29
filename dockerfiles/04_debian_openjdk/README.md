## Pasos a ejecutar

```shell
docker build -t pepesan/debian-jdk:bookworm-17 .
docker build -t pepesan/debian-jdk:latest .
docker login 
docker push pepesan/debian-jdk:bookworm-17
docker push pepesan/debian-jdk:latest
docker run --rm -it --name openjdk17 pepesan/debian-jdk:bookworm-17 /bin/bash
```


