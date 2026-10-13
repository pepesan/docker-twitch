#!/usr/bin/env bash
set -euo pipefail

docker exec -i openmetadata_mysql mysql -u root -ppassword <<'SQL'
-- Activar logs
SET GLOBAL general_log = 'ON';
SET GLOBAL log_output = 'TABLE';

-- Permisos
GRANT SELECT ON mysql.general_log TO 'openmetadata_user'@'%';
FLUSH PRIVILEGES;

-- Crear tabla y datos
USE openmetadata_db;

CREATE TABLE IF NOT EXISTS clientes (
  id INT PRIMARY KEY,
  nombre VARCHAR(100),
  email VARCHAR(100),
  ciudad VARCHAR(50),
  fecha_registro DATE
);

INSERT INTO clientes (id, nombre, email, ciudad, fecha_registro) VALUES
  (1, 'Juan Pérez', 'juan@email.com', 'Madrid', '2023-01-10'),
  (2, 'Ana López', 'ana@email.com', 'Barcelona', '2023-02-15'),
  (3, 'Carlos Ruiz', 'carlos@email.com', 'Valencia', '2023-03-20'),
  (4, 'Lucía Gómez', 'lucia@email.com', 'Sevilla', '2023-04-12'),
  (5, 'Pedro Martín', NULL, 'Madrid', '2023-05-01');
SQL


