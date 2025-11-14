from fastapi import FastAPI
from app.routers import items

app = FastAPI(
    title="Mi API con FastAPI",
    version="0.1.0",
    description="Ejemplo de proyecto FastAPI"
)

# Incluir routers
app.include_router(items.router)

@app.get("/", tags=["root"])
async def read_root():
    return {"message": "¡Hola, FastAPI!"}