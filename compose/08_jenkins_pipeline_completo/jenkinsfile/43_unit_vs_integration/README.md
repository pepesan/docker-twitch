# 43_unit_vs_integration

Separa los tests reales de `spring-boot-30-demo-maven` en dos stages:
**unitarios** (rápidos, `MainControllerTest` `@WebMvcTest`, mockea la capa
web) primero, e **integración** (lento, `SpringBoot30DemoMavenApplicationTests`
`@SpringBootTest`, levanta el contexto Spring completo) después. No se
modifica el repo real: las clases de test se seleccionan con `-Dtest`,
igual que `-DaltDeploymentRepository` en `32_maven_deploy_nexus`.

## Cómo probarlo

```shell
./01_create.sh   # da de alta (o actualiza) el job en Jenkins
./02_build.sh    # lo lanza con el valor por defecto (no falla nada)
./03_check.sh    # consulta el estado y log completo del último build
./04_delete.sh    # lo borra
```

Resultado esperado: `SUCCESS`, ambas stages ejecutadas (3 tests unitarios,
1 de integración).

**Desde la consola web**: menú lateral del build → enlace
**"Resultado de los tests"** (igual que en `40_junit_maven`) — junta el
resultado de ambas stages en un
único resumen, porque `junit` recoge todos los XML de
`target/surefire-reports/` en el `post { always {...} }`, sin distinguir
de qué stage vino cada uno.

## Fail-fast: forzar que falle el unitario

```shell
curl -u admin:admin -X POST \
  -H "$(curl -su admin:admin http://localhost:8082/crumbIssuer/api/json | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['crumbRequestField']+': '+d['crumb'])")" \
  --data-urlencode "FORZAR_FALLO_UNITARIO=true" \
  http://localhost:8082/job/43_unit_vs_integration/buildWithParameters
```

Con `FORZAR_FALLO_UNITARIO=true`, la stage de unitarios escribe un test
adicional (`ForzarFalloTest`, solo en el workspace efímero del build, no en
el repo) que falla siempre, y lo incluye en el `-Dtest`. Verificado:
resultado `FAILURE`, con la consola mostrando literalmente
`Stage "Tests de integracion (lentos)" skipped due to earlier failure(s)`
— la stage de integración ni se ejecuta.

**Gotcha**: como con `41_test_trend`, la primera vez hay que lanzar el job
sin parámetros (`02_build.sh`) — Jenkins no lo reconoce como parametrizado
hasta que el pipeline se ejecuta una vez y registra el bloque
`parameters {}`; si no, `buildWithParameters` responde `HTTP 400
"is not parameterized"`.

**Otro gotcha, más sutil**: `-Dtest=Clase#metodoQueNoExiste` **no** sirve
para forzar un fallo — Surefire lo trata como "0 tests" y da
`BUILD SUCCESS`, no `BUILD FAILURE`. Hace falta un test que falle de
verdad (`Assertions.fail(...)`), no un filtro que no encuentre nada.
