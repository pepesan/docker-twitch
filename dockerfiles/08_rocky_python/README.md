## Pasos a ejecutar

```shell
docker build -t pepesan/rockylinux-python:9.4-3.11-pandas .
docker build -t pepesan/rockylinux-python:latest .
docker login 
docker push pepesan/rockylinux-python:9.4-3.11-pandas
docker push pepesan/pepesan/rockylinux-python:latest
docker run --rm -it --name rocky pepesan/rockylinux-python:9.4-3.11-pandas
```


