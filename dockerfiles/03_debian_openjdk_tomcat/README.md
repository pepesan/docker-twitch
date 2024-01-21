## Pasos a ejecutar

```shell
docker build -t pepesan/debian-jdk-tomcat:bookworm-17-10 .
docker build -t pepesan/debian-jdk-tomcat:latest .
docker login 
docker push pepesan/debian-jdk-tomcat:bookworm-17-10
docker push pepesan/debian-jdk-tomcat:latest
docker run -d --name tomcat -p 8083:8080 pepesan/debian-jdk-tomcat:bookworm-17-10
```

## Acceso al tomcat
[http://localhost:8083/](http://localhost:8083/)

## Acceso a volúmenes
```shell
docker run -d --name tomcat -p 8083:8080 -v ./webapps:/deploy/tomcat/webapps pepesan/debian-jdk-tomcat:bookworm-17-10
```

