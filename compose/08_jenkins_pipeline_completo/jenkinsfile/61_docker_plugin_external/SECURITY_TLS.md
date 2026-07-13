# Guía de Securización de la API de Docker mediante TLS (Puerto 2376)

Exponer la API de Docker por TCP sin cifrar (`tcp://0.0.0.0:2375`) es aceptable únicamente en laboratorios aislados o entornos de desarrollo local muy controlados. En producción, esto supone una **vulnerabilidad crítica**, ya que cualquiera que tenga acceso a la red podría ejecutar contenedores con privilegios de root en la máquina host.

Para securizar esta conexión, se debe habilitar **TLS mutuo (mTLS)** sobre el puerto estándar **`2376`**. Esto garantiza que:
1. La comunicación esté **cifrada**.
2. Jenkins verifique la **identidad del host Docker** (evitando ataques Man-in-the-Middle).
3. El host Docker verifique la **identidad de Jenkins** antes de aceptar cualquier orden (autenticación por cliente certificado).

---

## Paso 1: Generación de Certificados (Autoridad de Certificación, Servidor y Cliente)

Ejecuta los siguientes comandos en tu máquina (o en el host remoto) usando `openssl` para generar tu propia Autoridad de Certificación (CA) y firmar los certificados.

### 1.1. Crear la Autoridad de Certificación (CA)
```bash
# Generar la clave privada de la CA
openssl genrsa -aes256 -out ca-key.pem 4096

# Crear el certificado público de la CA (rellena los datos de tu organización)
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
```

### 1.2. Generar las claves y certificado para el Servidor Docker (LXC)
> [!IMPORTANT]
> Sustituye `10.207.154.80` por la dirección IP real de tu máquina Docker remota o su nombre de dominio.

```bash
# Generar clave privada del servidor
openssl genrsa -out server-key.pem 4096

# Generar la solicitud de firma de certificado (CSR)
openssl req -subj "/CN=10.207.154.80" -sha256 -new -key server-key.pem -out server.csr

# Configurar el Subject Alternative Name (SAN) para admitir la IP y localhost
echo "subjectAltName = DNS:localhost,IP:10.207.154.80,IP:127.0.0.1" > extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf

# Firmar el certificado del servidor con nuestra CA
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

### 1.3. Generar las claves y certificado para el Cliente (Jenkins)
```bash
# Generar clave privada del cliente
openssl genrsa -out key.pem 4096

# Generar la solicitud de firma para el cliente
openssl req -subj '/CN=jenkins-controller' -new -key key.pem -out client.csr

# Configurar el certificado para uso exclusivo de autenticación de cliente
echo "extendedKeyUsage = clientAuth" > extfile-client.cnf

# Firmar el certificado del cliente con nuestra CA
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

### 1.4. Limpieza de archivos temporales
```bash
rm -v client.csr server.csr extfile.cnf extfile-client.cnf
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem
```

---

## Paso 2: Configurar el Docker Daemon Remoto (LXC)

1. Mueve las claves públicas y privadas generadas del servidor a la carpeta `/etc/docker/` del nodo externo:
   * `ca.pem` (Certificado CA) -> `/etc/docker/ca.pem`
   * `server-cert.pem` (Certificado público de la máquina) -> `/etc/docker/server-cert.pem`
   * `server-key.pem` (Clave privada de la máquina) -> `/etc/docker/server-key.pem`

2. Modifica el archivo `/etc/docker/daemon.json` para indicarle que use TLS y valide los certificados entrantes:
   ```json
   {
     "hosts": [
       "unix:///var/run/docker.sock",
       "tcp://0.0.0.0:2376"
     ],
     "tls": true,
     "tlsverify": true,
     "tlscacert": "/etc/docker/ca.pem",
     "tlscert": "/etc/docker/server-cert.pem",
     "tlskey": "/etc/docker/server-key.pem"
   }
   ```

3. Reinicia el servicio de Docker:
   ```bash
   systemctl daemon-reload
   systemctl restart docker
   ```

---

## Paso 3: Configurar Jenkins

Para permitir que el plugin de Docker de Jenkins se conecte de forma segura:

### 3.1. Añadir Credenciales TLS en Jenkins
1. Ve a **Administrar Jenkins (Manage Jenkins) > Credentials (Credenciales)**.
2. Selecciona tu dominio (ej. Global) y haz clic en **Add Credentials (Añadir credenciales)**.
3. En **Kind (Tipo)**, selecciona la opción **Docker Host Certificate Authentication**.
4. Rellena los campos con los archivos del cliente generados en el **Paso 1**:
   * **Client Key:** Pega el contenido de `key.pem`.
   * **Client Certificate:** Pega el contenido de `cert.pem`.
   * **Server CA Certificate:** Pega el contenido de `ca.pem`.
5. Asigna un ID descriptivo, por ejemplo: `docker-external-tls-creds`.

### 3.2. Configurar la nube de Jenkins
1. Ve a **Administrar Jenkins (Manage Jenkins) > Clouds (Nubes)**.
2. Selecciona la nube `docker-external`.
3. Cambia la **Docker Host URI** al puerto seguro:
   `tcp://10.207.154.80:2376` (Puerto 2376).
4. En **Server Credentials**, selecciona la credencial que acabamos de crear (`docker-external-tls-creds`).
5. Haz clic en **Test Connection**.
   * Debería conectarse de forma cifrada y devolver la versión de Docker exitosamente.
6. Haz clic en **Save**.
