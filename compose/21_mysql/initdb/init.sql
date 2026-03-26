USE appdb;

CREATE TABLE usuarios (
                          id INT AUTO_INCREMENT PRIMARY KEY,
                          nombre VARCHAR(100),
                          email VARCHAR(100) UNIQUE
);

INSERT INTO usuarios (nombre, email) VALUES
                                         ('Juan', 'juan@email.com'),
                                         ('Ana', 'ana@email.com');