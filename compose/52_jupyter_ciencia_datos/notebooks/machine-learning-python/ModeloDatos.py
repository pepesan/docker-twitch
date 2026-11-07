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


class ModeloDatos(DynamicDocument):
    position = DecimalField(required=True)
    torque = DecimalField(required=True)
    codenumber = DecimalField(required=True)
    temperature = FloatField(required=True)
    timestamp = DateTimeField(default=datetime.utcnow)
    meta = {
        'indexes': [
            'timestamp',
            'codenumber',
        ]
    }

    def __str__(self):
        return self.position + ":" + str(self.torque) + ":" + str(self.timestamp) + ":" + str(self.codenumber)
