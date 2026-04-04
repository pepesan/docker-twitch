#!/bin/bash

echo "Comprobando autenticación del usuario admin..."

RESULT=$(mongosh "mongodb://admin:password_segura@localhost:27017/admin?authSource=admin" --quiet --eval 'db.runCommand({ connectionStatus: 1 }).ok' 2>/dev/null | tr -d '[:space:]')

if [ "$RESULT" = "1" ]; then
  echo "OK: autenticación correcta"
else
  echo "ERROR: autenticación fallida"
  exit 1
fi

