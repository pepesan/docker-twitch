## Pasos a ejecutar

```shell
docker build -t pepesan/debian-jdk-tomcat-war:bookworm-17-10-1.0 .
docker build -t pepesan/debian-jdk-tomcat-war:latest .
docker login 
docker push pepesan/debian-jdk-tomcat-war:bookworm-17-10
docker push pepesan/debian-jdk-tomcat-war:latest
docker run -d --name tomcat-war -p 8084:8080 pepesan/debian-jdk-tomcat-war:bookworm-17-10
```

## Acceso a la aplicación 
[http://localhost:8083/app](http://localhost:8083/app)

## Acceso a volúmenes
```shell
docker run -d --name tomcat -p 8083:8080 -v ./webapps:/deploy/tomcat/webapps pepesan/debian-jdk-tomcat-war:bookworm-17-10
```




