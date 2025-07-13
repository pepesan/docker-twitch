FROM jenkins/jenkins:lts-jdk21
USER root

# Instala Docker CLI (y sus dependencias)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      git \
      lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce docker-ce-cli docker-buildx-plugin && \
    usermod -aG docker jenkins && \
    rm -rf /var/lib/apt/lists/*

# Configuración del usuario jenkins
RUN mkdir -p /home/jenkins
# Creación del directorio de la clave SSH pública al contenedor
RUN mkdir -p /home/jenkins/.ssh

RUN chown -R jenkins:jenkins /home/jenkins
# Vuelve a usuario jenkins
USER jenkins


