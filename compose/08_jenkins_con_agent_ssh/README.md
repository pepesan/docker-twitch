# Servidor Jenkins Controller con agente SSH
Aquí tenemos un ejemplo de cómo levantar un servidor Jenkins con un agente SSH. El agente SSH se conecta al servidor Jenkins y permite ejecutar trabajos en el contenedor del agente.
## Requisitos
- Docker
- Docker Compose
## Creación de la Estructura del proyecto a nivel de carpeta
```shell
mkdir -p  ./jenkins_home
mkdir -p  ./jenkins_home_agent
chmod -R 777 ./jenkins_home ./jenkins_home_agent
```
## Arranque del servidor Jenkins Controller 
```shell
docker compose -p jenkins_controller up  -d --build
```
## Acceso al servidor Jenkins
Accede a la interfaz web de Jenkins en `http://localhost:8081` y sigue las instrucciones para completar la configuración inicial. Necesitarás el token de desbloqueo que se encuentra en el archivo `jenkins_home/secrets/initialAdminPassword` dentro del contenedor.
o sino puede ver el log
```shell
docker compose logs jenkins-controller -f 
```
## Instalación del Jenkins Controller
1. Accede a la interfaz web de Jenkins.
2. Mete el token de desbloqueo que se encuentra en el archivo `jenkins_home/secrets/initialAdminPassword` dentro del contenedor o revisa los logs del contenedor con `docker compose logs jenkins-controller -f`.
3. Sigue las instrucciones para instalar los plugins recomendados.
4. Crea un usuario administrador.
5. Configura el nombre del Jenkins Controller y la URL.
6. Completa la configuración inicial.

## Parada del servidor Jenkins Controller
```shell
docker compose down -p jenkins_controller
```

## Arranque del servidor Jenkins Controller con Agente SSH
```shell
docker compose up -p jenkins_controller_agent -f compose-controller-agent.yaml -d --build
```

## Configuración de las credenciales SSH
Para que el agente SSH pueda conectarse al servidor Jenkins, debes configurar las credenciales SSH en Jenkins:
1. Ve a "Administrar Jenkins" > "Administrar credenciales".
2. Haz clic en "Agregar credenciales".
3. Selecciona "SSH Username with private key".
4. Introduce el nombre de usuario jenkins y la clave privada del agente SSH del fichero id_ed25519.
5. Guarda las credenciales.

## Limpieza de los contenedores
```shell
docker compose down
./clean_env.sh
```
## Conclusiones
Con este ejemplo, puedes levantar un servidor Jenkins con un agente SSH que se conecta al servidor y permite ejecutar trabajos en el contenedor del agente. Puedes personalizar la configuración según tus necesidades y añadir más agentes SSH si es necesario.
