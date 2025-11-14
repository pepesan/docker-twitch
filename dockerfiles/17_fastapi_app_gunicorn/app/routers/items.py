from fastapi import APIRouter, HTTPException

router = APIRouter(
    prefix="/items",
    tags=["items"]
)

fake_db = {"foo": {"name": "Foo", "price": 50}}

@router.get("/", summary="Listar ítems")
async def read_items():
    return list(fake_db.values())

@router.get("/{item_id}", summary="Obtener ítem por ID")
async def read_item(item_id: str):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")
    return fake_db[item_id]