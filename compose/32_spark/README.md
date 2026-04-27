# Demo Apache Spark — Docker Compose

## Imágenes usadas

| Servicio     | Imagen          | Notas                                    |
|--------------|-----------------|------------------------------------------|
| spark-master | spark:python3   | Imagen oficial Docker Hub                |
| spark-worker | spark:python3   | Imagen oficial Docker Hub                |
| jupyter      | spark:python3   | Misma imagen + jupyter instalado via pip |

## Interfaces web

| Servicio     | URL                   |
|--------------|-----------------------|
| Spark Master | http://localhost:8080 |
| Spark Worker | http://localhost:8081 |
| Jupyter      | http://localhost:8888 |

## Arrancar

```bash
docker compose up -d
```

Jupyter tarda ~60s en instalar el paquete notebook. Seguir progreso:

```bash
docker logs -f jupyter
```

Cuando aparezca `Jupyter Server ... is running`, abrir http://localhost:8888
El notebook de demo está en `demo_spark.ipynb`.

## Contenido del notebook

1. **RDD — WordCount** — `flatMap → map → reduceByKey` (paradigma MapReduce a bajo nivel)
2. **DataFrame API** — agregación de ventas con `groupBy`, `agg`, `avg`
3. **Spark SQL** — misma lógica en SQL sobre una vista temporal
4. **Plan de ejecución** — `explain(mode='formatted')` para ver la optimización de Catalyst

## Verificar jobs en el clúster

Tras ejecutar cualquier celda con `.show()`, ir a http://localhost:8080
→ sección "Running Applications" o "Completed Applications"

## Parar

```bash
docker compose down
```