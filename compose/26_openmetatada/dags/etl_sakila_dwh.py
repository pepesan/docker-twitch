"""ETL real de Sakila hacia el almacén de datos (dwh_sakila), dentro del mismo MySQL.

Cada tarea carga una tabla del almacén a partir de una tabla de origen. Los
`inlets`/`outlets` declaran qué tablas de OpenMetadata lee y escribe cada tarea:
la ingestión de pipelines de Airflow los usa para construir el linaje.
"""
from datetime import datetime, timedelta

from airflow.sdk import dag, task
from sqlalchemy import create_engine, text

ENGINE_URL = "mysql+mysqldb://etl_user:etl_pass@mysql:3306/dwh_sakila"
SAKILA = "mysql_sakila.default.sakila"
DWH = "mysql_dwh.default.dwh_sakila"


def _load(ddl: str, table: str, select: str) -> int:
    """Crea la tabla destino si no existe y la recarga por completo.

    La recarga (DELETE + INSERT) va en una única transacción: quien consulte la tabla
    nunca la ve vacía a medias. No se usa TRUNCATE porque es DDL y confirma al instante.
    """
    engine = create_engine(ENGINE_URL)
    with engine.begin() as conn:
        conn.execute(text(ddl))
        conn.execute(text(f"DELETE FROM {table}"))
        result = conn.execute(text(f"INSERT INTO {table} {select}"))
        return result.rowcount


@dag(
    dag_id="etl_sakila_dwh",
    description="Carga el almacén de datos dwh_sakila desde sakila",
    schedule=timedelta(hours=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,  # al despausar nace una ejecución programada; las manuales esperan a que acabe
    is_paused_upon_creation=True,
    default_args={"owner": "equipo_comercial", "retries": 1, "retry_delay": timedelta(minutes=1)},
    tags=["sakila", "etl"],
)
def etl_sakila_dwh():
    @task(inlets={"tables": [f"{SAKILA}.customer"]}, outlets={"tables": [f"{DWH}.dim_cliente"]})
    def carga_dim_cliente():
        rows = _load(
            """CREATE TABLE IF NOT EXISTS dim_cliente (
                 customer_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
                 nombre VARCHAR(91), email VARCHAR(50), active TINYINT(1))""",
            "dim_cliente",
            "SELECT customer_id, CONCAT(first_name, ' ', last_name), email, active FROM sakila.customer",
        )
        print(f"dim_cliente: {rows} filas")

    @task(inlets={"tables": [f"{SAKILA}.payment"]}, outlets={"tables": [f"{DWH}.fact_pagos"]})
    def carga_fact_pagos():
        rows = _load(
            """CREATE TABLE IF NOT EXISTS fact_pagos (
                 payment_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
                 customer_id SMALLINT UNSIGNED, amount DECIMAL(5,2), payment_date DATETIME)""",
            "fact_pagos",
            "SELECT payment_id, customer_id, amount, payment_date FROM sakila.payment",
        )
        print(f"fact_pagos: {rows} filas")

    carga_dim_cliente()
    carga_fact_pagos()


etl_sakila_dwh()
