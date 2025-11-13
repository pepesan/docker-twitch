#!/usr/bin/env bash
docker compose down
docker volume rm wp_database
docker volume rm wp_html_volume


