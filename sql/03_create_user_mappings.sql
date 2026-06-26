-- 03_create_user_mappings.sql
-- Ejecutar en el nodo principal / gateway.
-- Asocia el usuario local postgres con las credenciales usadas para acceder a los nodos remotos.

DROP USER MAPPING IF EXISTS FOR postgres SERVER history_server;
DROP USER MAPPING IF EXISTS FOR postgres SERVER current_server;

CREATE USER MAPPING FOR postgres
SERVER history_server
OPTIONS (
    user 'postgres',
    password 'CHANGE_ME_POSTGRES_PASSWORD'
);

CREATE USER MAPPING FOR postgres
SERVER current_server
OPTIONS (
    user 'postgres',
    password 'CHANGE_ME_POSTGRES_PASSWORD'
);
