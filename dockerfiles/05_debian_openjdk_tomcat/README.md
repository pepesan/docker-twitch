## Pasos a ejecutar

```shell
docker build -t pepesan/tomcat:10.1.49-jdk21 .
docker build -t pepesan/tomcat:latest .
docker login 
docker push pepesan/tomcat:10.1.49-jdk21
docker push pepesan/tomcat:latest
# version sin volumenes personalizados
docker run -d --name tomcat \ 
  -p 8083:8080 pepesan/tomcat:10.1.49-jdk21
# version con volumen personalizado
docker run -d --name tomcat \ 
  -v ./webapps:/deploy/tomcat/webapps \
  -p 8083:8080 pepesan/tomcat:10.1.49-jdk21
```

## Acceso al tomcat
[http://localhost:8083/](http://localhost:8083/)

## Acceso a volúmenes
```shell
docker run -d --name tomcat -p 8083:8080 -v ./webapps:/deploy/tomcat/webapps pepesan/tomcat:10.1.49-jdk21
```

