-- Esquema y datos ficticios de operaciones bancarias para las prácticas de
-- los Módulos 3 y 4 del curso "Python para Auditoría" (BBK).
-- Simula el sistema corporativo de operaciones al que el Módulo 3 se conecta
-- por SQL (directamente y a través de HUE) y con el que se concilian los
-- ficheros Excel/CSV de las sucursales.

CREATE TABLE operaciones (
    id_operacion VARCHAR(10) PRIMARY KEY,
    cuenta       VARCHAR(20) NOT NULL,
    importe      NUMERIC(12, 2) NOT NULL,
    fecha        DATE NOT NULL,
    sucursal     VARCHAR(10) NOT NULL
);

INSERT INTO operaciones (id_operacion, cuenta, importe, fecha, sucursal) VALUES
    ('OP-001', 'ES00-1234', 1200.00, '2026-01-05', 'MAD01'),
    ('OP-002', 'ES00-5678',   75.00, '2026-01-06', 'MAD01'),
    ('OP-003', 'ES00-1234', 3400.00, '2026-01-06', 'BIL02'),
    ('OP-004', 'ES00-9012',  980.00, '2026-01-07', 'BIL02'),
    ('OP-005', 'ES00-3456', 15200.00, '2026-01-07', 'MAD01'),
    ('OP-006', 'ES00-5678', 2100.00, '2026-01-08', 'BIL02');
