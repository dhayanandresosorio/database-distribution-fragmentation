-- 02_create_foreign_servers.sql
-- Ejecutar en el nodo principal / gateway.
-- Define los servidores remotos que contienen parte de los datos.

DROP SERVER IF EXISTS history_server CASCADE;
DROP SERVER IF EXISTS current_server CASCADE;

CREATE SERVER history_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '192.168.1.16',
    dbname 'dvdrental',
    port '5432'
);

CREATE SERVER current_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '192.168.1.17',
    dbname 'dvdrental',
    port '5432'
);
