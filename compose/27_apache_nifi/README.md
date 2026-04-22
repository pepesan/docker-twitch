# Prueba de Apache Nifi

## Arranque
./00.init.sh
./01_launch.sh

## Servicio
https://localhost:8443/nifi

usuario: admin
contraseña: Admin1234567890Admin1234567890

Dentro del canvas principal sigue los siguientes pasos:

Arrastra un Procesor al canvas
Selecciona
GenerateFlowFile

Dentro de las configuraciones (rueda dentada izquierda)

Scheduling:
Run Schedule: 10 sec
Properties
Custom Text: hola desde nifi
Unique FlowFiles: false
Apply

Arrastra un Procesor al canvas
Selecciona
PutFile

Relationships:
failure:
terminate checked
success:
terminate checked
Scheduling:
Run Schedule: 10 sec
Properties:
Directory: /tmp/nifi-output
Conflict Resolution Strategy: replace


## Asociación de los dos elementos
Arrastra la flecha del GenerateFlowFile al PutFile

Elige success
Pulsa en Add

Debería ver la asociación hecha

## Arranca los procesadores 
Con el GenerateFlowFile selecionado pulsa el botón de play
Con el PutFile selecionado pulsa el botón de play

## Comprueba que se están escribiendo los datos
revisa los ficheros output/ para ver si tienen los datos colocados

## Selecciona elementos
Shift + Arrastrar con el raton

## Copiar el flujo

Control + C

## Exportar FLujo

Pega el contenido del Control + C de antes a un fichero JSON
Y guardalo

## Importar el Flujo

Copia el contenido del fichero de antes
Pega con Control + V dentro del canvas de Nifi


