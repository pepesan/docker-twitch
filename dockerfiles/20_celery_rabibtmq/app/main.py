from fastapi import FastAPI
from worker import add

app = FastAPI()

@app.get("/sumar")
def sumar():
    task = add.delay(3, 4)
    return {"task_id": task.id}
