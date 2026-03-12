# Etapa 1: binarios uv/uvx
FROM ghcr.io/astral-sh/uv:latest AS uvx

# Etapa 2: runtime Debian 13
FROM debian:trixie

# Certs
RUN apt update && apt install -y ca-certificates && apt clean

# Copiar uv/uvx
COPY --from=uvx /uv /uvx /bin/

# Python gestionado por uv (3.13) y venv local
ENV UV_PYTHON=3.13 \
    UV_PYTHON_PREFERENCE="only-managed" \
    UV_PROJECT_ENVIRONMENT=".venv" \
    PATH="/root/.local/bin:/bin:${PATH}"

WORKDIR /app

# 1) Copia sólo metadata de deps para cachear
COPY pyproject.toml uv.lock* ./

# 2) Instala deps (se cachea mientras no cambien los archivos anteriores)
RUN uv sync --frozen --no-cache

# 3) Copia el resto del proyecto
COPY . /app

# Si tu proyecto es empaquetable y quieres reinstalarlo dentro de la venv:
# RUN uv pip install -e .

EXPOSE 80
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
