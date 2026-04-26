import pandas as pd
import os

INPUT_PATH = '/opt/airflow/data/input/datos.csv'
OUTPUT_PATH = '/opt/airflow/data/output/datos_procesados.csv'
INFORME_PATH = '/opt/airflow/data/output/informe.txt'

def verificar_fichero():
    if not os.path.exists(INPUT_PATH):
        raise FileNotFoundError(f'No se encuentra el fichero: {INPUT_PATH}')

def transformar():
    df = pd.read_csv(INPUT_PATH)
    df.columns = [c.strip().lower() for c in df.columns]
    df = df.dropna()
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)

def validar():
    df = pd.read_csv(OUTPUT_PATH)
    assert len(df) > 0, 'El fichero procesado está vacío'
    assert df.isnull().sum().sum() == 0, 'Existen valores nulos tras la transformación'

def generar_informe():
    df = pd.read_csv(OUTPUT_PATH)
    with open(INFORME_PATH, 'w') as f:
        f.write(f'Filas procesadas: {len(df)}\n')
        f.write(f'Columnas: {list(df.columns)}\n')
        f.write(f'Valores nulos: {df.isnull().sum().sum()}\n')