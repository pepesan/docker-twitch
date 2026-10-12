#!/bin/bash

# xdg-open en Linux, open en macOS
OPEN=$(command -v xdg-open || command -v open)
"$OPEN" http://localhost:8585
# Inicia sesión con las credenciales
# predeterminadas
# (admin@open-metadata.org/admin) y
# después podemos ir a
# Configuraciones -> Miembros ->  Users
# y añadir los usuarios que queramos.
