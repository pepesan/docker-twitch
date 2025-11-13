#!/usr/bin/env bash
# Create volumes directories with proper permissions
mkdir -p volumes volumes/data volumes/static
# Set permissions to allow Docker to read/write
sudo chmod -R 777 volumes
# Launch the Docker Compose services in detached mode
docker compose up -d

