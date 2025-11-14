from celery import Celery

celery_app = Celery(
    "worker",
    broker="amqp://admin:admin@rabbitmq:5672//",
    backend=None  # o 'rpc://' si quieres resultados
)

@celery_app.task
def add(x, y):
    return x + y
