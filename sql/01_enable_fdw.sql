-- 01_enable_fdw.sql
-- Ejecutar en el nodo principal / gateway.
-- Activa la extensión postgres_fdw para poder conectar con servidores PostgreSQL remotos.

CREATE EXTENSION IF NOT EXISTS postgres_fdw;
