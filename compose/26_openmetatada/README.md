# Demostración de Open Metadata

Open Metadata es una plataforma de código abierto para la gestión de metadatos en entornos de datos. Proporciona una solución centralizada para catalogar, organizar y gobernar los datos en una organización. A continuación, se presenta una demostración básica de cómo configurar y utilizar Open Metadata.
## Referencias
https://docs.open-metadata.org/v1.12.x/quick-start/local-docker-deployment

## Lanzamiento de Open Metadata
Para lanzar Open Metadata, puedes utilizar Docker Compose. Asegúrate de tener Docker y Docker Compose instalados en tu sistema. 
Después arranca
```bash
docker-compose up -d
```
Esto iniciará los servicios necesarios para Open Metadata, incluyendo la base de datos y la aplicación web.
## Acceso a la Interfaz de Usuario
Una vez que los servicios estén en funcionamiento, puedes acceder a la interfaz de usuario de Open Metadata a través de tu navegador web. La URL predeterminada es:
```
http://localhost:8585
```
Inicia sesión con las credenciales 
predeterminadas 
(admin@open-metadata.org/admin) y 
después podemos ir a 
Configuraciones -> Miembros ->  Users
y añadir los usuarios que queramos.

## Acceso a Airflow
Open Metadata también incluye Airflow para la orquestación de flujos de trabajo. Puedes acceder a la interfaz de Airflow en:
```
http://localhost:8080
```
Inicia sesión con las credenciales 
predeterminadas (admin/admin) para gestionar tus flujos de trabajo.

Estas están configuradas en las variables de entorno.
- Username: AIRFLOW_ADMIN_USER
- Password: AIRFLOW_ADMIN_PASSWORD

## Recorrer los DAG de Airflow
En la interfaz de Airflow, 
puedes explorar los 
DAGs (Directed Acyclic Graphs) que 
representan los flujos de trabajo. 
Puedes activar, desactivar y ejecutar los DAGs según tus necesidades. Además, puedes revisar los logs y el estado de las tareas para monitorear la ejecución de tus flujos de trabajo.

## Parar los servicios
Cuando hayas terminado de usar Open Metadata, puedes detener los servicios utilizando Docker Compose:
```bash
docker-compose down
```
Esto detendrá y eliminará los contenedores, redes y volúmenes asociados con Open Metadata.

## Configuración de Mysql para tener permisos de log 

Entramos a la instancia de Mysql:
```shell
docker exec -it openmetadata_mysql mysql -u root -ppassword
```

Y ejecutamos:
```sql
SET GLOBAL general_log = 'ON';
SET GLOBAL log_output = 'TABLE';

GRANT SELECT ON mysql.general_log TO 'openmetadata_user'@'%';
FLUSH PRIVILEGES;
```

Metemos una serie de datos para la parte práctica:
```sql
USE openmetadata_db;
CREATE TABLE clientes (
                          id INT PRIMARY KEY,
                          nombre VARCHAR(100),
                          email VARCHAR(100),
                          ciudad VARCHAR(50),
                          fecha_registro DATE
);
INSERT INTO clientes VALUES
                         (1, 'Juan Pérez', 'juan@email.com', 'Madrid', '2023-01-10'),
                         (2, 'Ana López', 'ana@email.com', 'Barcelona', '2023-02-15'),
                         (3, 'Carlos Ruiz', 'carlos@email.com', 'Valencia', '2023-03-20'),
                         (4, 'Lucía Gómez', 'lucia@email.com', 'Sevilla', '2023-04-12'),
                         (5, 'Pedro Martín', NULL, 'Madrid', '2023-05-01');

```

Nos salimos de la consola de mysql (exit) y del contenedor (exit).


## Conexión a la base de datos
Open Metadata permite la ingestión de metadatos desde diversas fuentes, incluyendo bases de datos. Para conectar una base de datos a Open Metadata, puedes seguir estos pasos:
1. Accede a la interfaz de Open Metadata.
2. Navega a la sección de "Configuraciones" -> Servicios
3. Haz clic en "Bases de Datos" y pulsa "Agregar nuevo Servicio".
4. Selecciona el tipo de base de datos que deseas conectar, por ejemplo, MySQL en este caso.
5. Ponle un nombre al servicio, por ejemplo "MySQL OpenMetaData".
6. Configura los detalles de conexión, incluyendo nombre de usuario (openmetadata_user) 
y contraseña (openmetadata_password),
el host y puerto (mysql:3306), de tu nombre de base de datos MySQL (openmetadata_db) y esquema (openmetadata_db).
7. Pulsamos en el botón de probar la conexión y debería darnos todo en verde. 
8. Pulsamos en Ok y Siguiente.
9. Después podríamos seleccionar patrones de las bases de datos a incluir o excluir, pero podemos dejarlo
vacío para que incluya todo.
10. Pulsamos en Save
11. Debería aparecer una perspectiva y un agente en estado pendiente. 
12. Deberían de ir apareciendo los datos de la base de datos de opendata 

## Práctica de Gobierno de Datos
### Exploración
Desde el apartado de Explorar-> Bases de datos -> llegar hasta las Tablas de openmetadata-db
Podemos entrar a cualquiera de las tablas y ver todo su contenido incluidas las columnas y demás.
Por ejemplo table_entity que guarda la metadata de las tablas catalogadas en OpenMetadata.
O user_entity, para gestiona los usuarios como entidad de gobierno.
En nuestro caso buscaremos a tabla que habíamos creado llamada clientes.

## Dentro de la tabla
Tenemos disponibles las columnas, puede identificar cada una de ellas incluyendo los tipos de campos,
que gestiona los usuarios de la bbdd

Vayamos a documentar la tabla pulsa el botón de Editar

Saldrá una tabla con los campos y podemos irlos editando uno a uno
Empezando por las descripciones de columna.
Haz doble click en cada uno de ellas y vete editando.

Así estás catalogando los datos, documentándolos y metiendo 
gobierno semántico.
Guarda los datos y volvemos al listado de columnas.

## Clasificar los datos con Tags
Identificamos datos sensibles / personales (clave en RGPD)
Ahora es cuando pondremos las etiquetas a campos clave como los 
campos email y nombre que le pondremos PII.Sensitive

- PII = Personally Identifiable Information
- En español: Datos personales identificables
- Sensitive = sensibles

Estos datos:

- no se pueden usar libremente
- requieren protección
- tienen implicaciones legales

Ese tag permite:

- identificar datos sensibles
- aplicar políticas de acceso
- auditar el uso
- facilitar cumplimiento legal

## Glosario 
Gobernar -> Glosario

Añadir
Nombre :Glosario Comercial
Descripción: Descripción del Glosario Comercial
Guardar

Añadir Término
Cliente
Persona que ha realizado un registro o mantiene una relación comercial con la empresa.
Guardar

Añadir Término
ID Cliente
Identificativo único de cliente
Guardar

Añadir Término
Email de Cliente
Dirección de correo electrónico utilizada para identificar y contactar con un cliente.
Guardar

## Asociamos términos y datos
Nos vamos a la tabla de clientes
En la pestaña de productos en el apartado derecho viene
un Término de glosario con un +
Silo pulsas puedes asociar el término cliente a la tabla
Si seleccionamos el nombre de la columna email, 
podemos ver también los términos de glosario y podemos 
asociar al del Email 
También el id podemos asociarlo al ID de cliente

Estamos haciendo lo mismo:

añadir significado
clasificar datos
conectar negocio

## Observabilidad
Vamos a Observabilidad -> Test de Calidad

Añadir Caso de Prueba
Elemento que deba probarse: Nivel de Columna
Seleccionamos la tabla clientes
Selecionamos la columna email
Seleccionamos el tipo de prueba Column Values to Be Not Null
Comprobamos que ha asignado un nombre a la prueba
Crear tubería: test_calidad_clientes
Ejecutaba bajo demanda
Pulsamos en crear

## Casos de prueba y tuberías asignados a tabla
Entramos a la tabla desde Explorar -> BBDD
Buscamos tabla -> Entramos a la tabla
Observabilidad -> Calidad de datos 
Debería aparecer nuestro caso de prueba y la tubería

Podemos ejecutar la tubería desde la pestaña Tuberías
y desde los tres puntos seleccionar Ejecutar

Podemos ver el log desde registros

Y en la pestaña Casos de prueba debería aparecer como 
Fallido

# Añadir propietarios

Desde la vista de tabla podemos ver los propietarios y 
podemos añadirlos
Selecionando el lapiz y desde la pestaña de usuarios 
seleccionar el usuario que queremos asociar
por ejemplo admin

Ya tendríamos responsable del dato asignado

# Linaje
Desde la pantalla de tabla podemos acceder a linaje de la tabla
Pulsando en la pestaña Linaje
Deberíamos ver el origen de esa tabla




