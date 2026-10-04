#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose --env-file compose.env up -d

cat <<'EOF'

URLs:                  directa                  vía Caddy (HTTPS; requiere /etc/hosts, ver README)
  Portal (Dashy)       http://localhost:4000    https://portal.lab.local / https://lab.local (usuario curso)
  Grafana              http://localhost:3030    https://grafana.lab.local       (login propio)
  Prometheus           http://localhost:9090    https://prometheus.lab.local    (usuario curso)
  Alertmanager         http://localhost:9093    https://alertmanager.lab.local  (usuario curso)
  Loki (API)           http://localhost:3100    https://loki.lab.local          (usuario curso)
  Alloy (UI)           http://localhost:12345   https://alloy.lab.local         (usuario curso)
  Tempo (API)          http://localhost:3200    https://tempo.lab.local         (usuario curso)
  Blackbox Exporter    http://localhost:9115    (sin vhost)
  hot-rod (demo app)   http://localhost:8082    https://hotrod.lab.local        (usuario curso)
Si cambiaste CADDY_HTTPS_PORT en compose.env, añade :<puerto> a las URLs de Caddy.
EOF
