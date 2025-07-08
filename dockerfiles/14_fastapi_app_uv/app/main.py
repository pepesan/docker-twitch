from fastapi import FastAPI

app = FastAPI(
    title="Mi API con FastAPI",
    version="0.1.0",
    description="Ejemplo de proyecto FastAPI"
)



@app.get("/", tags=["root"])
async def read_root():
    return {"message": "¡Hola, FastAPI!"}