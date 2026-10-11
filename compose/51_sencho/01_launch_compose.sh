#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d

cat <<'MSG'

Sencho:       http://localhost:1852
Credenciales: no hay usuario por defecto; en el primer acceso Sencho pide
              crear la cuenta de administrador (elige tú usuario y contraseña).
Stack de prueba: desde la UI despliega "hola-nginx" -> http://localhost:8095
MSG
