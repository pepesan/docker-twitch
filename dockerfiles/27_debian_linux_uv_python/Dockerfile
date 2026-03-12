# imagen base
FROM debian:trixie

# Variables de entorno
ENV PYTHON_VERSION=3.14 \
    PATH="/root/.local/bin:$PATH"

# Actualización del sistema e instalación de herramientas
RUN apt update && \
    apt -y upgrade && \
    apt install -y wget tar gzip && \
    apt clean

# -----------------------------
# Instalación de uv
# -----------------------------
WORKDIR /root

# Instalador standalone oficial de uv
RUN wget -qO- https://astral.sh/uv/install.sh | sh

# -----------------------------
# Preparación de la aplicación
# -----------------------------
WORKDIR /deploy

# Copiamos los requisitos para aprovechar la cache de Docker
COPY requirements.txt /deploy/

# -----------------------------
# Creación del entorno virtual
# -----------------------------
# Descarga Python 3.14 y crea el venv en .venv (sin usar --path)
RUN uv venv --python $PYTHON_VERSION .venv

# Instalación de dependencias dentro del entorno
RUN uv pip install -r requirements.txt

# -----------------------------
# Copia de la aplicación y ejecución
# -----------------------------
COPY app.py /deploy/

# Inicia la app usando uv para asegurar el entorno correcto
ENTRYPOINT ["uv", "run", "python", "app.py"]