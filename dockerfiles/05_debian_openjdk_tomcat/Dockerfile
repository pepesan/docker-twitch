# Imagen basada en Debian Bookworm
FROM debian:trixie

ENV TOMCAT_VERSION=10.1.49

RUN apt update && \
    apt upgrade -y

RUN apt install -y openjdk-21-jdk curl && \
    apt clean

RUN mkdir -p /deploy

WORKDIR /deploy

# https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.49/bin/apache-tomcat-10.1.49-deployer.tar.gz
RUN curl -o tomcat.tgz https://archive.apache.org/dist/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN tar -xvf tomcat.tgz

RUN mv apache-tomcat-$TOMCAT_VERSION tomcat

EXPOSE 8080

VOLUME /deploy/tomcat/webapps

VOLUME /deploy/tomcat/conf

WORKDIR /deploy/tomcat

ENTRYPOINT ["bin/catalina.sh", "run"]

CMD []






