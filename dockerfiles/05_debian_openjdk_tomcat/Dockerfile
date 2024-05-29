# Imagen basada en Debian Bookworm
FROM debian:bookworm

ENV TOMCAT_VERSION=10.1.18

RUN apt update && \
    apt upgrade -y

RUN apt install -y openjdk-17-jdk curl && \
    apt clean

RUN mkdir -p /deploy

WORKDIR /deploy

RUN curl -o tomcat.tgz https://dlcdn.apache.org/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN tar -xvf tomcat.tgz

RUN mv apache-tomcat-$TOMCAT_VERSION tomcat

EXPOSE 8080

VOLUME /deploy/tomcat/webapps

VOLUME /deploy/tomcat/conf

WORKDIR /deploy/tomcat

ENTRYPOINT ["bin/catalina.sh", "run"]

CMD []






