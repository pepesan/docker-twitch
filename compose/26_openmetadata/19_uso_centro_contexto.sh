#!/usr/bin/env bash
# Uso 2: CENTRO DE CONTEXTO.
# Publica artículos en el Centro de contexto de OpenMetadata y los vincula a
# las tablas de Sakila a las que se refieren. Es idempotente.
set -euo pipefail
cd "$(dirname "$0")"

PYTHONUNBUFFERED=1 PYTHONPATH=. python3 - <<'PY'
import sys, time
import om_lib
from om_lib import call, tag, DB

om_lib.login()

ARTICLES = [
    ("guia_sakila", "Guía del modelo Sakila", ["customer", "rental", "payment", "film", "inventory"],
     """# Guía del modelo Sakila

Sakila modela un videoclub con varias tiendas.

## Tablas principales
- **customer**: clientes registrados en una tienda.
- **film**: catálogo de películas; **inventory** son las copias físicas de cada tienda.
- **rental**: un cliente se lleva una copia de una película.
- **payment**: el pago asociado a un alquiler.

## Relaciones clave
`customer` 1—N `rental` N—1 `inventory` N—1 `film`, y `rental` 1—N `payment`.

## Consejo
Para ingresos por cliente usa la tabla derivada `resumen_ventas_cliente` en lugar de recalcularlos."""),
    ("politica_pii", "Política de datos personales (PII)", ["customer", "address", "staff"],
     """# Política de datos personales (PII)

Los datos que identifican a una persona están etiquetados como `PII.Sensitive`:

- Clientes: nombre, apellidos y correo electrónico.
- Empleados: nombre, apellidos, correo, usuario y contraseña.
- Direcciones: dirección, teléfono y código postal.

## Reglas
1. No se exportan fuera del entorno sin anonimizar.
2. El acceso se limita al Equipo Comercial.
3. Toda tabla derivada que incluya estas columnas debe heredar la etiqueta."""),
    ("calidad_del_dato", "Cómo interpretar los tests de calidad", ["customer", "address", "payment"],
     """# Cómo interpretar los tests de calidad

Los tests se ejecutan cada hora y se ven en **Observabilidad -> Test de Calidad**.

- **Success**: se cumple la regla.
- **Failed**: se incumple; mira el detalle (por ejemplo `nullCount`) y decide si es un error del dato o de la regla.

## Caso de ejemplo
`address_address2_no_nulo` falla a propósito: `address2` es opcional y casi siempre está vacío."""),
]

print("Uso 2: centro de contexto")
admin = call("GET", "/users/name/admin")
for name, title, related, body in ARTICLES:
    refs = [{"id": call("GET", f"/tables/name/{DB}.{t}")["id"], "type": "table"} for t in related]
    call("PUT", "/contextCenter/pages", {
        "name": name, "displayName": title, "pageType": "Article",
        "description": body, "page": {}, "relatedEntities": refs,
        "entityStatus": "Approved", "owners": [{"id": admin["id"], "type": "user"}]})
    print(f"  artículo: {title}")
PY
