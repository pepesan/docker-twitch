# Jupyter para análisis y ciencia de datos

Entorno de laboratorio compuesto por JupyterLab y dos servicios de datos: MongoDB y MariaDB. Los ejemplos están en `notebooks/machine-learning-python/`; se conservan las rutas relativas originales de sus CSV, modelos auxiliares e imágenes. El notebook `notebooks/00_primeros_pasos.ipynb` sigue disponible.

## Arrancar y acceder

```bash
cd compose/52_jupyter_ciencia_datos
docker compose up --build -d
```

Abre <http://localhost:8888> e introduce el token predeterminado `cambia-este-token`. Para cambiarlo:

```bash
JUPYTER_TOKEN='un-token-propio' docker compose up --build -d
```

Jupyter espera a que MongoDB y MariaDB estén listos. Jupyter se publica solo en `127.0.0.1:8888`; las bases no publican puertos al host y se alcanzan desde el kernel por `mongodb:27017` y `mariadb:3306`. Las notebooks y sus datos estáticos están en el volumen de host `notebooks/`.

## Bases de datos

Credenciales predeterminadas de laboratorio (cámbialas si se expone Jupyter en una red):

| Servicio | Host/puerto desde Jupyter | Base | Usuario | Contraseña |
|---|---|---|---|---|
| MongoDB | `mongodb:27017` | `test` | `ml_lab` | `ml_lab_local_only` |
| MariaDB | `mariadb:3306` | `ml_lab` | `ml_lab` | `ml_lab_local_only` |

MongoDB requiere autenticación en la base `admin`; las credenciales root se inicializan con `MONGO_ROOT_USER` y `MONGO_ROOT_PASSWORD`. `Modelos.py` y `ModeloDatos.py` usan `MONGO_URI`, configurada por defecto para el MongoDB de Compose. Puedes reemplazar `MONGO_URI` y las variables `MARIADB_*` al ejecutar Compose. `08_mariadb_conexion.ipynb` demuestra una conexión SQL de solo lectura con `mysql-connector-python` y las variables `MARIADB_HOST`, `MARIADB_PORT`, `MARIADB_DATABASE`, `MARIADB_USER` y `MARIADB_PASSWORD`.

MongoDB y MariaDB persisten en volúmenes Docker nombrados `mongodb_data` y `mariadb_data`, no en el repositorio. Reiniciar o ejecutar `docker compose down` conserva esos datos. Para eliminarlos de forma permanente: `docker compose down -v` (borra las bases del laboratorio).

## Dependencias y ejemplos

La imagen base usa Python 3.12 e instala JupyterLab/Notebook, IPython kernel, bibliotecas habituales de datos (NumPy, pandas, SciPy, Matplotlib, Seaborn, scikit-learn, statsmodels, Plotly, PyArrow, Excel) y conectores MongoEngine/PyMongo y MySQL.

Los extras se mantienen separados para evitar inflar la imagen base:

```bash
docker compose exec -u root jupyter python -m pip install -r /opt/jupyter/requirements-visualization.txt
docker compose exec -u root jupyter python -m pip install -r /opt/jupyter/requirements-web.txt
docker compose exec -u root jupyter python -m pip install -r /opt/jupyter/requirements-deep-learning.txt
docker compose exec -u root jupyter python -m pip install -r /opt/jupyter/requirements-kaggle.txt
```

Después de instalar requisitos opcionales, reinicia Jupyter para actualizar kernels. Algunas limitaciones específicas están anotadas al inicio de las notebooks: TensorFlow/Hub usa descargas grandes, red y puede ser lento en CPU; `tflearn` y ejemplos TensorFlow heredados pueden no ser compatibles con versiones actuales; el ejemplo Boston llama a `load_boston`, eliminado de scikit-learn (hay un ejemplo alternativo de California Housing); PyQtGraph necesita Qt y una pantalla; exportar árboles puede necesitar el ejecutable Graphviz además de `pydotplus`; ejemplos Flask se ejecutan como procesos de desarrollo, no como servicios Compose. Descargas Kaggle, Bokeh/seaborn datasets y modelos remotos requieren Internet. La configuración de Compose no incluye TensorFlow, Qt ni aplicaciones Flask.

## Operación y seguridad

```bash
docker compose logs -f jupyter
docker compose logs -f mongodb mariadb
docker compose down                 # parar, conservar notebooks y bases
docker compose build --no-cache     # reconstruir tras cambiar requirements
docker compose down -v              # eliminar bases persistentes (destructivo)
```

El token y las credenciales incluidos son conocidos y **solo para el laboratorio local**. Jupyter queda enlazado a `127.0.0.1` por defecto; no cambies ese enlace ni publiques el puerto en redes no confiables con valores predeterminados. Quien acceda a Jupyter puede ejecutar código con acceso a datos y credenciales del Compose. Antes de permitir acceso desde una red, configura credenciales propias y un token fuerte, y usa TLS y control de acceso. Los puertos de las bases permanecen internos a la red de Compose.
