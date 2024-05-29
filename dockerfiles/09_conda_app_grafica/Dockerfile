FROM continuumio/anaconda3
RUN mkdir -p /deploy
WORKDIR /deploy
# copia fichero de requisitos
COPY requirements.txt /deploy/requirements.txt
# instala dependencias
RUN conda install -y -n base --file requirements.txt
COPY test.py /deploy/test.py
CMD ["ipython", "test.py"]