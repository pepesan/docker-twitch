# Ejemplo de uso de MongoDB Community "In-Memory" con Docker Compose

Este ejemplo muestra cómo configurar y ejecutar una instancia de MongoDB Community Edition con almacenamiento en memoria utilizando Docker Compose.
## Requisitos Previos
- Tener Docker y Docker Compose instalados en tu sistema.
- Conocimientos básicos de Docker y Docker Compose.
- Familiaridad con MongoDB.
- Acceso a la imagen de MongoDB Community Edition que soporte almacenamiento en memoria.
- Conexión a internet para descargar la imagen de Docker.
- Espacio suficiente en disco para las imágenes de Docker.
- Permisos adecuados para ejecutar Docker en tu sistema.

## Creación del directorio del montaje en tmpfs

Antes de ejecutar el contenedor, crea un directorio en tu sistema que se utilizará para el montaje en tmpfs. Por ejemplo:

```bash
mkdir -p /data/db
```
Asegúrate de que el usuario que ejecuta Docker tenga permisos de lectura y escritura en este directorio.
 
## Ejecución del contenedor
```bash
docker compose up -d
```
Esto iniciará el contenedor de MongoDB Community Edition con almacenamiento en memoria.
## Verificación del estado del contenedor
Puedes verificar que el contenedor está en funcionamiento utilizando el siguiente comando:
```bash
docker compose ps
```
Deberías ver el contenedor de MongoDB en la lista de contenedores en ejecución.
```bash
docker inspect mongo-inmemory --format '{{json .HostConfig.Tmpfs}}
```
Deberías ver una salida que indica que el directorio `/data/db` está montado como tmpfs.
```raw
{"/data/db":"rw,noexec,nosuid,size=1G"}
```
Deberíamos poder ajustar el tamaño del tmpfs según nuestras necesidades en el archivo `compose.yaml`.

## Conexión a MongoDB
Puedes conectarte a la instancia de MongoDB utilizando un cliente MongoDB. Por ejemplo, si
tienes el cliente `mongo` instalado, puedes conectarte de la siguiente manera:
```bash
mongosh
```
Luego, dentro del shell de MongoDB, puedes verificar que la base de datos está funcionando correctamente
```javascript
show dbs
```

## Meter datos de prueba
Puedes insertar algunos datos de prueba para verificar que todo funciona correctamente. Por ejemplo:
```javascript
use testdb
db.testcollection.insertOne({name: "test", value: 123})
```
Luego, puedes consultar los datos para asegurarte de que se han insertado correctamente:
```javascript
db.testcollection.find()
```
## Detener y eliminar el contenedor
Cuando hayas terminado de usar MongoDB, puedes detener y eliminar el contenedor utilizando el siguiente comando
```bash
docker compose down
```
Esto detendrá y eliminará el contenedor de MongoDB.
## Notas adicionales
- Ten en cuenta que los datos almacenados en memoria se perderán cuando el contenedor se detenga o reinicie. Asegúrate de hacer copias de seguridad de los datos importantes si es necesario.
- Puedes ajustar la configuración del contenedor en el archivo `compose.yaml` según tus necesidades.
- Consulta la [documentación oficial de MongoDB](https://www.mongodb.com/docs/manual/) para obtener más información sobre la configuración y el uso de MongoDB.






