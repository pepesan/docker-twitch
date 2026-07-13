# 13_matrix

`matrix {}` permite ejecutar dinámicamente un conjunto de stages variando parámetros definidos en múltiples ejes (axes). Es ideal para ejecutar las mismas pruebas en múltiples navegadores y sistemas operativos de forma paralela y automatizada.

En este ejemplo se simula el lanzamiento de pruebas E2E (End-to-End) combinando:
- **Navegadores (BROWSER)**: Chrome, Firefox, Safari
- **Sistemas Operativos (OS)**: Linux, Windows

También se hace uso del bloque `excludes` para evitar combinaciones incompatibles o no deseadas (por ejemplo, ejecutar Safari bajo Linux).

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza y espera el resultado
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`. En los logs de Jenkins podrás ver cómo se ejecutan de manera independiente y paralela las diferentes combinaciones válidas:
- Chrome en Linux
- Chrome en Windows
- Firefox en Linux
- Firefox en Windows
- Safari en Windows

Se omitirá automáticamente la combinación Safari en Linux debido a la sección `excludes`.
