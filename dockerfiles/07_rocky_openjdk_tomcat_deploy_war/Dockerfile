# Imagen basada en Debian Bookworm
FROM rockylinux:9.3

ENV TOMCAT_VERSION=10.1.24

RUN dnf -y update

RUN dnf install -y java-21-openjdk curl-minimal

RUN mkdir -p /deploy

WORKDIR /deploy

# https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18-deployer.tar.gz
RUN curl -o tomcat.tgz https://archive.apache.org/dist/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN tar -xvf tomcat.tgz

RUN mv apache-tomcat-$TOMCAT_VERSION tomcat

EXPOSE 8080

VOLUME /deploy/tomcat/webapps

VOLUME /deploy/tomcat/conf

WORKDIR /deploy/tomcat

COPY sample.war webapps/app.war

ENTRYPOINT ["bin/catalina.sh", "run"]

CMD []





