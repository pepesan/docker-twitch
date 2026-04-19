USE openmetadata_db;

CREATE TABLE clientes (
                          id INT PRIMARY KEY,
                          nombre VARCHAR(100),
                          email VARCHAR(100),
                          ciudad VARCHAR(50),
                          fecha_registro DATE
);

INSERT INTO clientes VALUES
                         (1, 'Juan Pérez', 'juan@email.com', 'Madrid', '2023-01-10'),
                         (2, 'Ana López', 'ana@email.com', 'Barcelona', '2023-02-15'),
                         (3, 'Carlos Ruiz', 'carlos@email.com', 'Valencia', '2023-03-20'),
                         (4, 'Lucía Gómez', 'lucia@email.com', 'Sevilla', '2023-04-12'),
                         (5, 'Pedro Martín', NULL, 'Madrid', '2023-05-01');
