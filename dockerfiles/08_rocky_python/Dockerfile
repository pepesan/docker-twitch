# imagen basada en Rocky Linux 9.5
FROM rockylinux/rockylinux:9.5

ENV PYTHON_VERSION=3.12
# Actualizamos el sistema
RUN dnf -y update

#instalamos wget
RUN dnf install -y wget

WORKDIR /root

# instalamos miniconda
RUN mkdir -p miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm -rf ~/miniconda3/miniconda.sh

# configuramos el bash
RUN ~/miniconda3/bin/conda init bash

ENV CONDA_EXEC=/root/miniconda3/bin/conda
# creamos el entorno de python
RUN $CONDA_EXEC create -y --name prod python=$PYTHON_VERSION

# Crea el directorio de despliegue
RUN mkdir /deploy

# ejecuta sobre ese directorio
WORKDIR /deploy

# copia fichero de requisitos
COPY requirements.txt /deploy/requirements.txt

# instala dependencias
RUN $CONDA_EXEC install -y -n prod --file requirements.txt

# Copia aplicación
COPY app.py /deploy/app.py

# configura comando de ejecución
# CMD ["/root/miniconda3/bin/conda", "run", "-n", "prod", "python", "main.py"
# sólo podemos usar variables de entorno de esta manera
# CMD sh -c "$CONDA_EXEC run -n prod python main.py"
# Uso conjunto de entrypoint y CMD
ENTRYPOINT ["sh", "-c"]
CMD ["$CONDA_EXEC run -n prod python app.py"]




