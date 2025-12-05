#!/usr/bin/env bash
# Create volumes directories with proper permissions
mkdir -p data stacks
# Set permissions to allow Docker to read/write
sudo chmod -R 777 data stacks
# Launch the Docker Compose services in detached mode
docker compose up -d

