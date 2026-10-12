#!/usr/bin/env bash
# Fase 1 de gobierno del dato: DOCUMENTACIÓN.
# Añade descripciones a todas las tablas y vistas de Sakila y a sus columnas
# más relevantes. Requiere ./08_load_sakila.sh. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONPATH=. python3 - <<'PY'
import om_lib
from om_lib import call, tag, glossary_tag, patch_table, tag_ops, CATALOG

om_lib.login()

COLUMNS = {
    ("customer", "customer_id"): "Identificador único del cliente.",
    ("customer", "store_id"): "Tienda en la que está registrado el cliente.",
    ("customer", "first_name"): "Nombre del cliente.",
    ("customer", "last_name"): "Apellidos del cliente.",
    ("customer", "email"): "Correo electrónico del cliente.",
    ("customer", "address_id"): "Dirección del cliente (address).",
    ("customer", "active"): "Indica si el cliente está activo (1) o dado de baja (0).",
    ("customer", "create_date"): "Fecha de alta del cliente.",
    ("address", "address"): "Dirección postal.",
    ("address", "address2"): "Segunda línea de la dirección (opcional).",
    ("address", "district"): "Distrito, provincia o estado.",
    ("address", "postal_code"): "Código postal.",
    ("address", "phone"): "Teléfono de contacto.",
    ("staff", "first_name"): "Nombre del empleado.",
    ("staff", "last_name"): "Apellidos del empleado.",
    ("staff", "email"): "Correo electrónico del empleado.",
    ("staff", "username"): "Usuario de acceso del empleado.",
    ("staff", "password"): "Hash de la contraseña del empleado.",
    ("staff", "picture"): "Fotografía del empleado.",
    ("payment", "amount"): "Importe pagado.",
    ("payment", "payment_date"): "Fecha y hora del pago.",
    ("rental", "rental_date"): "Fecha y hora del alquiler.",
    ("rental", "return_date"): "Fecha y hora de devolución (NULL si no se ha devuelto).",
    ("film", "title"): "Título de la película.",
    ("film", "rental_rate"): "Precio del alquiler.",
    ("film", "rental_duration"): "Duración del alquiler en días.",
    ("film", "replacement_cost"): "Coste de reposición si no se devuelve.",
    ("film", "rating"): "Clasificación por edades (G, PG, PG-13, R, NC-17).",
    ("film", "length"): "Duración de la película en minutos.",
    ("actor", "first_name"): "Nombre del actor.",
    ("actor", "last_name"): "Apellidos del actor.",
    ("category", "name"): "Nombre de la categoría.",
    ("language", "name"): "Nombre del idioma.",
    ("city", "city"): "Nombre de la ciudad.",
    ("country", "country"): "Nombre del país.",
    ("customer_list", "name"): "Nombre completo del cliente.",
    ("customer_list", "zip code"): "Código postal.",
    ("customer_list", "notes"): "Muestra \"active\" si el cliente está activo.",
    ("staff_list", "name"): "Nombre completo del empleado.",
    ("staff_list", "zip code"): "Código postal.",
    ("sales_by_store", "store"): "Ciudad y país de la tienda.",
    ("sales_by_store", "manager"): "Nombre del responsable de la tienda.",
    ("sales_by_store", "total_sales"): "Suma de los pagos de la tienda.",
    ("sales_by_film_category", "category"): "Nombre de la categoría.",
    ("sales_by_film_category", "total_sales"): "Suma de los pagos de la categoría.",
}

print("Fase 1: documentación")
for table, (desc, _, _) in CATALOG.items():
    def ops(t, table=table, desc=desc):
        out = []
        if t.get("description") != desc:
            out.append({"op": "add", "path": "/description", "value": desc})
        for i, col in enumerate(t["columns"]):
            cdesc = COLUMNS.get((table, col["name"]))
            if cdesc and col.get("description") != cdesc:
                out.append({"op": "add", "path": f"/columns/{i}/description", "value": cdesc})
        return out
    patch_table(table, ops)
PY
