-- 05_validation_queries.sql
-- Consultas de comprobación para verificar que los servidores remotos y las foreign tables funcionan.

-- Ver servidores remotos configurados.
SELECT srvname, srvoptions
FROM pg_foreign_server;

-- Ver tablas foráneas disponibles.
SELECT foreign_table_schema, foreign_table_name, foreign_server_name
FROM information_schema.foreign_tables
ORDER BY foreign_table_schema, foreign_table_name;

-- Comprobar recuento de registros en nodos remotos.
SELECT 'history_remote.rental' AS source, COUNT(*) AS total
FROM history_remote.rental;

SELECT 'current_remote.rental' AS source, COUNT(*) AS total
FROM current_remote.rental;

-- Comparar datos entre nodos.
SELECT 'history' AS node, COUNT(*) AS total
FROM history_remote.rental
UNION ALL
SELECT 'current' AS node, COUNT(*) AS total
FROM current_remote.rental;

-- Consulta de ejemplo sobre datos remotos.
SELECT rental_id, rental_date, inventory_id, customer_id
FROM history_remote.rental
LIMIT 10;
