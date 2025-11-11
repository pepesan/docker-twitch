FROM grycap/cowsay:latest

RUN apt-get -y update && \
    apt -y upgrade  && \
    apt-get install -y fortunes && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove

CMD ["sh", "-c", "/usr/games/fortune -a | cowsay"]
