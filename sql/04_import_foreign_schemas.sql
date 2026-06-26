-- 04_import_foreign_schemas.sql
-- Ejecutar en el nodo principal / gateway.
-- Importa tablas remotas desde los nodos history y current hacia esquemas separados.
-- Ajustar la lista LIMIT TO si en el laboratorio se usan tablas diferentes.

CREATE SCHEMA IF NOT EXISTS history_remote;
CREATE SCHEMA IF NOT EXISTS current_remote;

IMPORT FOREIGN SCHEMA public
LIMIT TO (actor, film, inventory, rental, payment)
FROM SERVER history_server
INTO history_remote;

IMPORT FOREIGN SCHEMA public
LIMIT TO (actor, film, inventory, rental, payment)
FROM SERVER current_server
INTO current_remote;
