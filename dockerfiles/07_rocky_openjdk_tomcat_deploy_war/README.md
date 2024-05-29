## Pasos a ejecutar

```shell
docker build -t pepesan/rockylinux-jdk-tomcat-war:9.4-21-10-1.0 .
docker build -t pepesan/rockylinux-jdk-tomcat-war:latest .
docker login 
docker push pepesan/rockylinux-jdk-tomcat-war:9.4-21-10-1.0
docker push pepesan/rockylinux-jdk-tomcat-war:latest
docker run -d --name rockylinux-tomcat-war -p 8084:8080 pepesan/rockylinux-jdk-tomcat-war:9.4-21-10-1.0
```

## Acceso a la aplicación 
[http://localhost:8083/app](http://localhost:8083/app)

## Acceso a volúmenes
```shell
docker run -d --name tomcat -p 8083:8080 -v ./webapps:/deploy/tomcat/webapps pepesan/rockylinux-jdk-tomcat-war:bookworm-21-10-1.0
```




