#!/bin/bash

# xdg-open en Linux, open en macOS
OPEN=$(command -v xdg-open || command -v open)
"$OPEN" http://localhost:8080
# Inicia sesión con las credenciales
# predeterminadas (admin/admin) para gestionar
# tus flujos de trabajo.
# Estas están configuradas en las variables de entorno.
#- Username: AIRFLOW_ADMIN_USER
#- Password: AIRFLOW_ADMIN_PASSWORD
