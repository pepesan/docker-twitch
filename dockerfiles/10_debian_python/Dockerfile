# imagen basada en Ubuntu 24.04 jammy
FROM python:3.14.1-trixie

ENV PYTHON_VERSION=3.14

# Actualiza pip
RUN pip install --upgrade pip

# Crea el directorio de despliegue
RUN mkdir /deploy

# ejecuta sobre ese directorio
WORKDIR /deploy

# copia fichero de requisitos
COPY requirements.txt /deploy/requirements.txt

# instala dependencias
RUN pip install -r requirements.txt

# Copia aplicación
COPY app.py /deploy/app.py

# configura comando de ejecución
# CMD ["/root/miniconda3/bin/conda", "run", "-n", "prod", "python", "main.py"
# sólo podemos usar variables de entorno de esta manera
# CMD sh -c "$CONDA_EXEC run -n prod python main.py"
# Uso conjunto de entrypoint y CMD
ENTRYPOINT ["sh", "-c"]
CMD ["python app.py"]




