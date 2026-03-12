FROM debian:latest

RUN apt-get -y update && \
    apt -y upgrade  && \
    apt install -y iputils-ping

ENTRYPOINT ["ping", "-c 4"]
CMD ["google.com"]
