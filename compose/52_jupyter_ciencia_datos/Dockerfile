FROM python:3.12-slim

ENV JUPYTER_TOKEN=cambia-este-token \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /opt/jupyter
COPY requirements*.txt ./
RUN python -m pip install --upgrade pip && \
    python -m pip install -r requirements.txt && \
    useradd --create-home --shell /bin/bash jovyan && \
    mkdir -p /home/jovyan/work && \
    chown -R jovyan:jovyan /home/jovyan

USER jovyan
WORKDIR /home/jovyan/work
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--ServerApp.root_dir=/home/jovyan/work"]
