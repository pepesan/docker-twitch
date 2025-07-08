# Etapa 1: coger sólo el binario de uv/uvx
FROM ghcr.io/astral-sh/uv:latest AS uvx

# Etapa 2: imagen de runtime en Rocky Linux
FROM rockylinux/rockylinux:9.5

# (Opcional) Instalar CA root si la necesitas para HTTPS
RUN dnf install -y ca-certificates && \
    dnf clean all

# Copiar los binarios uv y uvx
COPY --from=uvx /uv /uvx /bin/

# Ajustar PATH y preferencias (usa sólo Python gestionado por uv)
ENV UV_PYTHON_PREFERENCE="only-managed"
ENV PATH="/root/.local/bin:/bin:${PATH}"

# Directorio de la aplicación
WORKDIR /app
COPY . /app

# Instalar las dependencias via lockfile
RUN uv sync --frozen --no-cache

# Exponer puerto 80
EXPOSE 80

# Comando por defecto: arranca FastAPI
CMD ["uv", "run", "fastapi", "dev", "--host", "0.0.0.0", "--port", "80"]