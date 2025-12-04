# Aplicación FastAPI de ejemplo

## Instalación de UV
```shell
curl -LsSf https://astral.sh/uv/install.sh | sh

# Script para añadir ~/.local/bin al PATH en ~/.bashrc

BASHRC="$HOME/.bashrc"
EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'

# Comprobamos si la línea ya existe en .bashrc
if grep -Fxq "$EXPORT_LINE" "$BASHRC"; then
  echo "La línea de exportación ya existe en $BASHRC"
else
  # Añadimos la línea al final de .bashrc
  echo "" >> "$BASHRC"
  echo "# Añadido por add_local_bin_to_path.sh: incluir ~/.local/bin en PATH" >> "$BASHRC"
  echo "$EXPORT_LINE" >> "$BASHRC"
  echo "Se ha añadido la exportación al final de $BASHRC"
fi
```
## Recargamos el archivo .bashrc para aplicar los cambios
```shell
source ~/.bashrc
```
## Comprobamos que uv está instalado
```shell
uv --version
```
## Arranque de la aplicación
```shell
uv run fastapi dev --host 0.0.0.0 --port 8000
``` 





