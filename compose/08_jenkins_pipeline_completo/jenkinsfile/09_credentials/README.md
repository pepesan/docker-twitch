# 09_credentials

`withCredentials` con los 4 tipos de credencial de Jenkins: usuario y
contraseña, texto secreto, clave SSH privada y fichero secreto. Jenkins
enmascara automáticamente (`****`) cualquier valor sensible que aparezca en
la consola.

## Cómo probarlo

```shell
./00_create_credentials.sh   # da de alta las 4 credenciales de demostración (idempotente)
./01_create.sh                # da de alta (o actualiza) el job en Jenkins
./02_build.sh                 # lo lanza y espera el resultado
./03_delete.sh                # lo borra
```

**Importante:** hay que ejecutar `00_create_credentials.sh` antes de
`02_build.sh` — el job falla si las credenciales `demo-user-pass`,
`demo-secret-text`, `demo-ssh-key` y `demo-config-file` no existen en
Jenkins todavía.

Resultado esperado: `SUCCESS`.
