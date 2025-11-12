# Etapa 1: coger sólo el binario de uv/uvx
FROM ghcr.io/astral-sh/uv:latest AS uvx

# Etapa 2: imagen de runtime en Rocky Linux
FROM rockylinux/rockylinux:9.5

# Certs
RUN dnf install -y ca-certificates && dnf clean all

# Copiar binarios uv y uvx
COPY --from=uvx /uv /uvx /bin/

# Forzar Python con wheels disponibles
ENV UV_PYTHON=3.12
ENV UV_PYTHON_PREFERENCE="only-managed"
ENV UV_PROJECT_ENVIRONMENT=".venv"
ENV PATH="/root/.local/bin:/bin:${PATH}"

# App
WORKDIR /app
COPY . /app

# Instalar dependencias usando el lockfile si existe
# (si no tienes uv.lock, quita --frozen)
RUN uv sync --frozen --no-cache

# Exponer puerto 80
EXPOSE 80

# Arranque (para prod suele ser mejor uvicorn que 'fastapi dev')
# Ajusta `main:app` al módulo/objeto real de tu aplicación
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
