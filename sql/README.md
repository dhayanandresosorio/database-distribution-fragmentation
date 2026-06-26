# SQL scripts

Esta carpeta contiene scripts SQL de apoyo para reproducir la parte principal del laboratorio de distribución y fragmentación con PostgreSQL.

Los scripts están pensados para ejecutarse desde el nodo principal o gateway, adaptando las IPs, nombres de base de datos o tablas si el laboratorio cambia.

Orden recomendado:

1. `01_enable_fdw.sql`
2. `02_create_foreign_servers.sql`
3. `03_create_user_mappings.sql`
4. `04_import_foreign_schemas.sql`
5. `05_validation_queries.sql`

> [!IMPORTANT]
> Las contraseñas aparecen como placeholders. Antes de ejecutar los scripts en un entorno real o de laboratorio, sustituir `CHANGE_ME_POSTGRES_PASSWORD` por la contraseña local correspondiente.
