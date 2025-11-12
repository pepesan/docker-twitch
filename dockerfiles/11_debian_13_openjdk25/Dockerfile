# Imagen basada en Debian Bookworm
FROM debian:trixie

RUN apt update && \
    apt upgrade -y

# instala openjdk-25 en debian 13\
RUN apt install -y wget
RUN wget https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb
RUN  dpkg -i jdk-25_linux-x64_bin.deb
RUN rm jdk-25_linux-x64_bin.deb