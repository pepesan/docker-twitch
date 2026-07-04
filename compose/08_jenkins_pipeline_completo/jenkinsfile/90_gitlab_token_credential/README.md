# 90_gitlab_token_credential

Da de alta en Jenkins la credencial necesaria para clonar el repo
**privado** `gitlab.com/cursosdedesarrollo/blog` (frontend Astro), y
verifica que funciona de verdad haciendo un checkout real en el
Jenkinsfile. Bloqueante para `91`/`92_build_astro_real`.

## Cómo conseguir el token real

### Opción A: token personal (recomendada — no depende de permisos del grupo)

Un **Personal Access Token** de tu propia cuenta funciona igual para
clonar por HTTPS, y **no está sujeto** a la restricción de "Project
access token creation is disabled in this group":

1. Entra en `gitlab.com` con la cuenta que tiene acceso a
   `cursosdedesarrollo/blog`.
2. Tu avatar (arriba a la derecha) → **Edit profile** → **Access Tokens**
   (o directamente `gitlab.com/-/user_settings/personal_access_tokens`).
3. **Token name**: algo descriptivo, p. ej. `jenkins-temario-docker`.
4. **Expiration date**: la que prefieras.
5. **Scopes**: marca solo **`read_repository`** — no hace falta nada más
   para clonar.
6. **Create personal access token** — el valor **solo se muestra una
   vez**, cópialo entonces.

### Opción B: token de proyecto (si tienes rol Owner del grupo)

Si prefieres un token limitado solo a ese proyecto (en vez de a toda tu
cuenta), hace falta que la creación de *project access tokens* esté
habilitada en el grupo — el mensaje "Project access token creation is
disabled in this group" significa que está desactivada y, por defecto,
**solo un Owner del grupo** puede reactivarla:

1. Como Owner del grupo `cursosdedesarrollo`: **Group → Settings →
   General → Permissions and group features**.
2. Marca la casilla **"Users can create project access tokens and group
   access tokens in this group"**.
3. Guarda, y entonces sí aparecerá la opción en
   `cursosdedesarrollo/blog → Settings → Access Tokens`.

**Nota**: en el plan gratuito de GitLab.com hay casos conocidos donde esa
casilla no aparece ni para el Owner (bug reportado en el propio GitLab —
ver `gitlab.com/gitlab-org/gitlab/-/issues/452639`). Si te pasa esto, usa
la Opción A — es la vía fiable independientemente del plan o los permisos
del grupo.

## Cómo probarlo

```shell
cp .env.example .env    # copia la plantilla
# edita .env y rellena GITLAB_BLOG_TOKEN con el token del paso anterior
./00_create_credentials.sh   # da de alta la credencial en Jenkins
./01_create.sh                # da de alta (o actualiza) el job
./02_build.sh                  # lo lanza y espera el resultado
./03_delete.sh                 # borra el job (la credencial se queda)
```

`.env` **nunca se comitea** (está en el `.gitignore` de esta carpeta) —
solo `.env.example` (sin el token real) va al repositorio.

Resultado esperado: `SUCCESS`, con `package.json encontrado: checkout OK`
en la consola. **Verificado end-to-end** con un token real (Personal
Access Token, Opción A).

## Detalles

- La credencial se da de alta como **usuario/contraseña**
  (`UsernamePasswordCredentialsImpl`), no como texto secreto — GitLab
  espera el token como contraseña junto a un usuario (por convención
  `oauth2`) en el checkout HTTPS, igual que se documenta en `.env.example`.
- `00_create_credentials.sh` es idempotente: si la credencial
  `gitlab-blog-token` ya existe, no la vuelve a crear.
- Si `.env` no existe o `GITLAB_BLOG_TOKEN` está vacío, el script falla
  con un mensaje explicando qué hacer, en vez de crear una credencial con
  la contraseña en blanco.
- **Gotcha**: la rama por defecto del repo es `master`, no `main` — no
  asumir, comprobar con `git ls-remote <url> | grep HEAD`.

## Lo que se descubrió explorando el repo (útil para `92`)

El checkout reveló que `blog` ya trae su propio `Dockerfile` multi-stage:
`node:22-alpine` + `corepack`/`pnpm build` en la fase de build, y
`nginxinc/nginx-unprivileged:alpine` sirviendo `dist/` (puerto `8080`) en
la fase final — confirma que la salida es estática. Sin `pnpm-lock.yaml`
comiteado, pero el propio Dockerfile usa `pnpm install --ignore-scripts`
sin `--frozen-lockfile`, así que no hace falta arreglar nada. `92` puede
reutilizar este Dockerfile directamente (`docker build .`), igual que
`33_build_publish_deploy` con el backend — no hace falta reimplementar los
pasos de build de Astro a mano en el Jenkinsfile.
