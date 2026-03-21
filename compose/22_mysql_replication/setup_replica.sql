-- Parar y limpiar configuración previa
STOP REPLICA;
RESET REPLICA ALL;

-- Configurar conexión al source usando GTID
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'mysql-source',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = 'replpass',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

-- Arrancar replicación
START REPLICA;

