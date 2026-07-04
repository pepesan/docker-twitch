# 08_input

`input` pausa el pipeline hasta que alguien lo aprueba o lo aborta desde la
UI. `scripts/build_job_input.sh` (no el `build_job.sh` genérico, que no
sabe nada de `input` y se quedaría esperando para siempre) detecta este
input pendiente vía la API de Jenkins y lo aprueba solo, para poder
verificar este ejemplo sin intervención manual.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza; el input pendiente se aprueba automáticamente
./03_delete.sh   # lo borra
```

Resultado esperado: `SUCCESS`, con "Input pendiente detectado... aprobando
automáticamente" en la salida de `02_build.sh`.

## Lanzarlo y aprobarlo a mano desde la consola web

Sin usar ningún script, todo desde `http://localhost:8082`:

1. Entra en el job: `Jenkins` → **`08_input`**.
2. Menú lateral izquierdo → **"Build Now"** — lanza el build.
3. El pipeline se para en la stage "Aprobacion manual". Dos formas de ver
   el mensaje y aprobarlo, con el mismo resultado:
   - Entra directamente en **"Console Output"** del build — el propio log
     muestra, al final, el mensaje `¿Aprobar el despliegue a produccion?`
     con los botones **"Desplegar"** / **"Abort"** ya insertados ahí mismo,
     sin necesidad de navegar a otra página.
   - O bien, en el menú lateral del build (`.../job/08_input/<build>/`),
     el enlace **"Paused for Input"** lleva a una página dedicada
     (`.../input`) con el mismo mensaje y los mismos dos botones.
4. Pulsa **"Desplegar"** (el texto de `ok` en el Jenkinsfile) para
   continuar, o **"Abort"** para cancelar el build.

Verificado: la página del input tiene como título
`Paused for Input : 08_input #9 - Jenkins`, con ambos botones presentes.
Solo puede pulsar "Desplegar"/"Abort" el usuario indicado en `submitter`
(aquí `admin`) — ver más abajo el caveat sobre administradores.

## Restringir quién puede aprobar (`submitter`)

El `input` lleva `submitter: 'admin'` — solo ese usuario (o los de ese
grupo) puede aprobarlo o abortarlo; cualquier otro usuario ve el botón
pero Jenkins le rechaza el click. Es el mecanismo real para limitar quién
puede dar luz verde a una acción sensible (por ejemplo, destruir un
despliegue — ver `33_build_publish_deploy`, que enlaza aquí).

Verificado: la consola del build muestra `Approved by admin`.

**Caveat importante**: en este laboratorio solo existe el usuario `admin`,
así que no se puede probar de verdad el rechazo — un usuario con permiso
`Overall/Administer` **siempre puede aprobar cualquier input**,
independientemente de lo que diga `submitter` (es una excepción de
Jenkins, no un bug). Para que la restricción tenga efecto real hace falta
un usuario sin ese permiso, lo cual requeriría configurar una estrategia
de autorización con roles (fuera del alcance de este laboratorio de un
solo usuario).

## Patrón real en producción

Este ejemplo (y `33_build_publish_deploy`) mezclan, por simplicidad
didáctica, la acción sensible y la aprobación en el mismo Jenkinsfile que
hace el resto del trabajo. En producción esto normalmente se separa en un
**job dedicado** solo para la acción que necesita aprobación (deploy a
producción, destruir un entorno, etc.), parametrizado y disparado
explícitamente por un humano — no como una stage más de un pipeline que
ya hizo build/test/deploy. Motivos: un build parado en un `input` ocupa un
executor y un workspace indefinidamente, y separar el job da control más
fino sobre quién puede lanzarlo y aprobarlo.
