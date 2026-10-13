#!/usr/bin/env bash
# Fase 3 de gobierno del dato: GLOSARIO DE NEGOCIO.
# Crea el glosario "Glosario Sakila" con sus términos y los asocia a todas las
# tablas y vistas de Sakila y a algunas columnas clave.
# Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, tag, glossary_tag, patch_table, tag_ops, CATALOG

om_lib.login()

TERMS = {
    "Cliente": "Persona que alquila películas en alguna de las tiendas.",
    "Alquiler": "Operación por la que un cliente se lleva una copia de una película durante un periodo.",
    "Pelicula": "Obra audiovisual del catálogo de la empresa.",
    "Pago": "Importe abonado por un cliente por un alquiler.",
    "Inventario": "Copia física de una película disponible en una tienda concreta.",
    "Empleado": "Persona que trabaja en una tienda y gestiona los alquileres.",
    "Tienda": "Punto de venta donde se gestionan inventario, empleados y alquileres.",
    "Actor": "Persona que interviene en una o varias películas del catálogo.",
    "Categoria": "Género o clasificación temática de una película.",
    "Idioma": "Lengua en la que está disponible una película.",
    "Direccion": "Ubicación postal (dirección, ciudad y país) de clientes, empleados y tiendas.",
}
COLUMN_TERMS = {
    "customer": {"customer_id": "Cliente"},
    "payment": {"amount": "Pago"},
    "rental": {"rental_id": "Alquiler"},
    "film": {"film_id": "Pelicula"},
    "inventory": {"inventory_id": "Inventario"},
    "staff": {"staff_id": "Empleado"},
    "store": {"store_id": "Tienda"},
    "actor": {"actor_id": "Actor"},
    "category": {"category_id": "Categoria"},
    "language": {"language_id": "Idioma"},
    "address": {"address_id": "Direccion"},
}

print("Fase 3: glosario")
call("PUT", "/glossaries", {
    "name": "GlosarioSakila", "displayName": "Glosario Sakila",
    "description": "Vocabulario de negocio del videoclub Sakila."})
for name, desc in TERMS.items():
    call("PUT", "/glossaryTerms", {"glossary": "GlosarioSakila", "name": name, "displayName": name, "description": desc})
    print(f"  término {name}")
for table, (_, _, term) in CATALOG.items():
    cols = {c: [glossary_tag(t)] for c, t in COLUMN_TERMS.get(table, {}).items()}
    patch_table(table, lambda t, term=term, cols=cols: tag_ops(t, [glossary_tag(term)], cols))
PY
