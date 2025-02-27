# Imagen basada en Debian Bookworm
FROM debian:bookworm

RUN apt update && \
    apt upgrade -y

# instala openjdk-21 en debian 12\
RUN apt install -y wget
RUN wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
RUN  dpkg -i jdk-21_linux-x64_bin.deb
RUN rm jdk-21_linux-x64_bin.deb