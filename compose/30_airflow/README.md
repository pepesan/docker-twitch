# Data Pipeline Lab — Airflow 3

## Requisitos
- Docker y Docker Compose instalados
- Mínimo 4GB de RAM disponibles para Docker

## Estructura
- `dags/` — definición del pipeline
- `scripts/` — lógica de transformación
- `data/input/` — depositar aquí el fichero CSV de entrada
- `logs/` — logs de ejecución de Airflow

## Levantar el entorno


### macOS / Windows
El fichero .env ya incluye el valor por defecto.
No debereíamos ejecutar dentro del 00_init.sh:
```shell
export AIRFLOW_UID=$(id -u)
```

### Iniciar los servicios
```shell
./00_init.sh
./01_launch.sh
```

### Acceder a la interfaz
http://localhost:8080
Usuario: airflow
Contraseña: docker compose logs airflow-api-server | grep -i password

## Instalar las dependencias

Ejecutar el siguiente comando dentro del contenedor de Airflow para instalar pandas:
```shell
./06_install_pandas.sh
```

## Verificar que la práctica ha funcionado correctamente

Una vez levantado el entorno y con el fichero `datos.csv` en `data/input/`:

**1. Activar el DAG**
En la interfaz web, localizar `pipeline_datos_lab` en la lista de DAGs
y activarlo con el interruptor de la izquierda si aparece en pausa.

**2. Lanzar una ejecución manual**
Hacer clic en el botón ▶ (Trigger DAG) a la derecha del nombre del DAG.

**3. Comprobar el estado de las tareas**
Entrar en el DAG y abrir la vista **Ejecuciones**. 
Entra en la última ejecución y revisar el estado de las tareas.
Todas las tareas deben aparecer en verde (success) en este orden:
inicio → verificar_fichero → transformar_datos → validar_calidad → generar_informe

**4. Revisar los logs de una tarea**
Hacer clic sobre cualquier tarea en verde y seleccionar **Logs**.
En `generar_informe` deberían aparecer las métricas del fichero procesado.

**5. Comprobar los ficheros de salida**
Verificar que se han generado correctamente en local:
- `data/output/datos_procesados.csv` — fichero transformado
- `data/output/informe.txt` — resumen con filas, columnas y nulos

## Parar el entorno
docker compose down

## Limpiar todo (incluidos volúmenes)
```shell
./20_destroy.sh
```