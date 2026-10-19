"""Utilidades comunes de los scripts de gobierno del dato de OpenMetadata."""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = os.environ.get("OPENMETADATA_API", "http://localhost:8585/api/v1")
EMAIL = os.environ.get("OPENMETADATA_ADMIN_EMAIL", "admin@open-metadata.org")
PASSWORD = os.environ.get("OPENMETADATA_ADMIN_PASSWORD", "admin")
DB = "mysql_sakila.default.sakila"
TABLE_FIELDS = "columns,tags,owners,domains"

_token = None


def call(method, path, body=None, ctype="application/json", ok_missing=False):
    req = urllib.request.Request(API + path, method=method)
    if _token:
        req.add_header("Authorization", "Bearer " + _token)
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        req.add_header("Content-Type", ctype)
    try:
        with urllib.request.urlopen(req, data, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if ok_missing and e.code == 404:
            return None
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:400]}")


def login_token(pwd_b64, tries=40, pause=15):
    """Login que espera si OpenMetadata bloquea la cuenta por intentos fallidos (p. ej. desde el navegador)."""
    body = json.dumps({"email": EMAIL, "password": pwd_b64}).encode()
    for _ in range(tries):
        req = urllib.request.Request(API + "/users/login", data=body, method="POST",
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read())["accessToken"]
        except urllib.error.HTTPError as e:
            msg = e.read().decode()
            if e.code == 401 and "Failed Login Attempts" in msg:
                print("  cuenta bloqueada temporalmente por OpenMetadata; reintento en %ds..." % pause, flush=True)
                time.sleep(pause)
                continue
            sys.exit(f"POST /users/login -> {e.code}: {msg[:400]}")
    sys.exit("POST /users/login: la cuenta sigue bloqueada tras esperar")


def login():
    global _token
    pwd = base64.b64encode(PASSWORD.encode()).decode()
    _token = login_token(pwd)
    if call("GET", f"/tables/name/{DB}.customer", ok_missing=True) is None:
        sys.exit("No existe mysql_sakila: ejecuta antes ./08_load_sakila.sh")


def tag(fqn, source="Classification"):
    return {"tagFQN": fqn, "source": source, "labelType": "Manual", "state": "Confirmed"}


def glossary_tag(term):
    return tag(f"GlosarioSakila.{term}", "Glossary")


def get_table(name):
    return call("GET", f"/tables/name/{DB}.{name}?fields={TABLE_FIELDS}")


def patch_table(name, build_ops):
    """Lee la tabla, calcula operaciones con build_ops(tabla) y las aplica si hay cambios."""
    t = get_table(name)
    ops = build_ops(t)
    if ops:
        call("PATCH", f"/tables/{t['id']}", ops, ctype="application/json-patch+json")
        print(f"  {name}: {len(ops)} cambios")
    else:
        print(f"  {name}: sin cambios")


def tag_ops(t, table_tags=(), column_tags=None):
    """Operaciones para añadir tags a la tabla y a columnas ({columna: [tags]}) que aún no los tengan."""
    ops = []
    have = {x["tagFQN"] for x in t.get("tags", [])}
    for wanted in table_tags:
        if wanted["tagFQN"] not in have:
            ops.append({"op": "add", "path": "/tags/-", "value": wanted})
    for i, col in enumerate(t["columns"]):
        chave = {x["tagFQN"] for x in col.get("tags", [])}
        for wanted in (column_tags or {}).get(col["name"], []):
            if wanted["tagFQN"] not in chave:
                ops.append({"op": "add", "path": f"/columns/{i}/tags/-", "value": wanted})
    return ops


# Catálogo de Sakila: tabla o vista -> (descripción, tier, término de glosario)
CATALOG = {
    # Tablas
    "customer": ("Clientes registrados en las tiendas, con sus datos de contacto.", "Tier.Tier1", "Cliente"),
    "rental": ("Alquileres realizados por los clientes.", "Tier.Tier1", "Alquiler"),
    "payment": ("Pagos asociados a los alquileres.", "Tier.Tier1", "Pago"),
    "film": ("Catálogo de películas.", "Tier.Tier2", "Pelicula"),
    "inventory": ("Copias de películas disponibles por tienda.", "Tier.Tier2", "Inventario"),
    "staff": ("Empleados de las tiendas.", "Tier.Tier2", "Empleado"),
    "store": ("Tiendas de la empresa y su responsable.", "Tier.Tier2", "Tienda"),
    "address": ("Direcciones de clientes, empleados y tiendas.", "Tier.Tier3", "Direccion"),
    "city": ("Ciudades de las direcciones.", "Tier.Tier3", "Direccion"),
    "country": ("Países de las ciudades.", "Tier.Tier3", "Direccion"),
    "actor": ("Actores y actrices que participan en las películas.", "Tier.Tier3", "Actor"),
    "film_actor": ("Relación entre películas y actores (N:M).", "Tier.Tier3", "Actor"),
    "category": ("Categorías o géneros de las películas.", "Tier.Tier3", "Categoria"),
    "film_category": ("Relación entre películas y categorías (N:M).", "Tier.Tier3", "Categoria"),
    "language": ("Idiomas de las películas.", "Tier.Tier3", "Idioma"),
    "film_text": ("Título y descripción de las películas para búsqueda de texto.", "Tier.Tier3", "Pelicula"),
    # Vistas
    "customer_list": ("Vista: clientes con su dirección, ciudad y país.", "Tier.Tier2", "Cliente"),
    "staff_list": ("Vista: empleados con su dirección, ciudad y país.", "Tier.Tier3", "Empleado"),
    "film_list": ("Vista: películas con su categoría y actores.", "Tier.Tier3", "Pelicula"),
    "nicer_but_slower_film_list": ("Vista: lo mismo que film_list con formato más cuidado y más lenta.", "Tier.Tier3", "Pelicula"),
    "actor_info": ("Vista: actores con las películas en las que participan por categoría.", "Tier.Tier3", "Actor"),
    "sales_by_store": ("Vista: ventas totales por tienda y su responsable.", "Tier.Tier2", "Pago"),
    "sales_by_film_category": ("Vista: ventas totales por categoría de película.", "Tier.Tier2", "Pago"),
}
