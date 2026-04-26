from airflow.sdk import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from datetime import datetime, timedelta
from scripts.transform import verificar_fichero, transformar, validar, generar_informe

default_args = {
    'owner': 'data-team',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='pipeline_datos_lab',
    default_args=default_args,
    start_date=datetime(2024, 1, 1),
    schedule='@daily',
    catchup=False,
) as dag:

    inicio = EmptyOperator(task_id='inicio')

    verificar = PythonOperator(
        task_id='verificar_fichero',
        python_callable=verificar_fichero,
    )

    transformar_task = PythonOperator(
        task_id='transformar_datos',
        python_callable=transformar,
    )

    validar_task = PythonOperator(
        task_id='validar_calidad',
        python_callable=validar,
    )

    informe = PythonOperator(
        task_id='generar_informe',
        python_callable=generar_informe,
    )

    inicio >> verificar >> transformar_task >> validar_task >> informe