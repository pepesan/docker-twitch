import os
from datetime import datetime
from mongoengine import *

connected = False
try:
    connect(host=os.getenv(
        "MONGO_URI",
        "mongodb://ml_lab:ml_lab_local_only@mongodb:27017/test?authSource=admin",
    ))
    connected = True
except Exception as e:
    print("No se puede conectar a MongoDB.")
    print("Asegúrate de que el servicio mongodb esté listo antes de ejecutar.")
    print("Motivo: " + str(e))

if connected:
    print("Se ha conectado al servidor")


class Modelo(DynamicDocument):
    nombre = StringField(required=True)
    primer_apellido = StringField(required=True)
    segundo_apellido = StringField(required=True)
    insert_datetime = DateTimeField(default=datetime.utcnow)
    batch = DecimalField(required=True)
    meta = {
        'indexes': [
            {
                'fields': ['nombre'],
                'unique': True
            },
            'primer_apellido',
            'segundo_apellido',
        ]
    }

    def __str__(self):
        return self.nombre + ":" + str(self.primer_apellido) + ":" + str(self.segundo_apellido)
