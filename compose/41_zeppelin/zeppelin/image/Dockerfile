# Imagen Zeppelin del curso, con un entorno Python moderno para el
# intérprete %python en vez del Python 3.7 (entorno "python_3_with_R") que
# trae por defecto apache/zeppelin:0.12.1. Ver ../../LECCIONESAPRENDIDAS.md.
FROM apache/zeppelin:0.12.1

USER root

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY requirements.txt /tmp/requirements.txt

RUN uv venv --python 3.14 /opt/venv-curso && \
    uv pip install --python /opt/venv-curso/bin/python --no-cache -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt && \
    mkdir -p /opt/zeppelin/.cache/matplotlib && \
    chown -R 1000:0 /opt/zeppelin/.cache

# Antepone el entorno nuevo al PATH: tanto el intérprete %python de Zeppelin
# (zeppelin.python = "python", resuelto por $PATH) como un "docker exec ...
# python3" usan a partir de ahora este Python 3.14 con las librerías del curso.
ENV PATH="/opt/venv-curso/bin:${PATH}"

USER 1000
