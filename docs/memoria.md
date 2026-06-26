# Memoria técnica - Database Distribution and Fragmentation

## 1. Resumen del laboratorio

En esta práctica he trabajado un escenario de bases de datos distribuidas utilizando PostgreSQL.

El objetivo ha sido simular un entorno con varios nodos PostgreSQL, donde un servidor principal actúa como punto de consulta y otros servidores almacenan parte de los datos. Para conectar estos nodos he utilizado la extensión `postgres_fdw`, que permite acceder desde PostgreSQL a tablas ubicadas en otros servidores PostgreSQL.

La práctica parte de la base de datos `dvdrental` y se centra en entender cómo se puede distribuir la información entre varias máquinas, manteniendo la posibilidad de consultar esos datos desde un nodo central.

> [!NOTE]
> Este laboratorio no está planteado como un despliegue de producción. Es una práctica técnica para entender distribución de datos, foreign tables, conexión entre nodos PostgreSQL y consultas remotas.

---

## 2. Objetivo de la práctica

El objetivo principal es construir un entorno distribuido con tres servidores PostgreSQL:

- un nodo principal o gateway;
- un nodo remoto para datos históricos;
- un nodo remoto para datos actuales.

Desde el nodo gateway se configuran conexiones hacia los otros nodos mediante `postgres_fdw`. Después se crean tablas foráneas para poder consultar datos remotos como si formasen parte del entorno local.

Con esta práctica se trabajan conceptos como:

- fragmentación de datos;
- distribución entre nodos;
- conexión remota entre servidores PostgreSQL;
- uso de `postgres_fdw`;
- creación de foreign servers;
- creación de user mappings;
- creación o importación de foreign tables;
- validación mediante consultas SQL.

---

## 3. Arquitectura del laboratorio

El laboratorio está formado por tres máquinas PostgreSQL.

```text
Gateway / nodo principal
IP: 192.168.1.15
Función: punto central de consulta

History node
IP: 192.168.1.16
Función: nodo remoto con parte de los datos

Current node
IP: 192.168.1.17
Función: nodo remoto con otra parte de los datos
```

Diagrama lógico:

```text
                 +-----------------------------+
                 | Gateway PostgreSQL          |
                 | 192.168.1.15                |
                 | Consulta datos remotos      |
                 +--------------+--------------+
                                |
              +-----------------+-----------------+
              |                                   |
              v                                   v
+-----------------------------+     +-----------------------------+
| History node                |     | Current node                |
| 192.168.1.16                |     | 192.168.1.17                |
| Fragmento de datos          |     | Fragmento de datos          |
+-----------------------------+     +-----------------------------+
```

> [!TIP]
> Antes de configurar `postgres_fdw`, es importante comprobar que los nodos se ven por red y que PostgreSQL permite conexiones remotas. Si no hay conectividad básica entre servidores, las foreign tables no funcionarán.

---

## 4. Preparación de los nodos

Cada máquina del laboratorio tiene PostgreSQL instalado y una base de datos `dvdrental`.

En la práctica se usan tres máquinas con IPs fijas dentro de la misma red:

```text
Gateway:
- IP: 192.168.1.15
- Usuario de sistema: isard
- Base de datos: dvdrental

History:
- IP: 192.168.1.16
- Usuario de sistema: isard
- Base de datos: dvdrental

Current:
- IP: 192.168.1.17
- Usuario de sistema: isard
- Base de datos: dvdrental
```

En la documentación original se usaban contraseñas concretas para las máquinas y para PostgreSQL. En esta versión se han sustituido por placeholders:

```text
CHANGE_ME_VM_PASSWORD
CHANGE_ME_POSTGRES_PASSWORD
```

> [!IMPORTANT]
> Las contraseñas reales no se publican en el repositorio. Los placeholders permiten documentar el proceso sin exponer credenciales personales.

---

## 5. Configuración de acceso remoto en PostgreSQL

Para que un nodo pueda conectarse a otro, PostgreSQL debe escuchar en la IP adecuada y permitir conexiones desde la máquina remota.

En cada servidor se revisa el archivo `postgresql.conf`.

```bash
isard@gateway:~$ sudo nano /etc/postgresql/16/main/postgresql.conf
```

En el nodo gateway:

```text
listen_addresses = '192.168.1.15'
```

En el nodo history:

```text
listen_addresses = '192.168.1.16'
```

En el nodo current:

```text
listen_addresses = '192.168.1.17'
```

Después se revisa el archivo `pg_hba.conf` para permitir las conexiones necesarias.

```bash
isard@gateway:~$ sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Ejemplo de regla para permitir acceso desde el nodo gateway al nodo history:

```text
host    dvdrental   postgres   192.168.1.15/32   scram-sha-256
```

Ejemplo de regla para permitir acceso desde el nodo gateway al nodo current:

```text
host    dvdrental   postgres   192.168.1.15/32   scram-sha-256
```

Tras modificar la configuración, se reinicia PostgreSQL en cada nodo afectado.

```bash
isard@history:~$ sudo systemctl restart postgresql
isard@current:~$ sudo systemctl restart postgresql
```

Se comprueba el estado del servicio:

```bash
isard@history:~$ sudo systemctl status postgresql
```

Salida esperada:

```text
Active: active
```

---

## 6. Configuración del usuario postgres

Para permitir conexiones entre nodos se configura una contraseña para el usuario `postgres`.

```bash
isard@history:~$ sudo -u postgres psql
```

Dentro de PostgreSQL:

```sql
ALTER ROLE postgres WITH PASSWORD 'CHANGE_ME_POSTGRES_PASSWORD';
```

Salida esperada:

```text
ALTER ROLE
```

Se repite el proceso en los nodos que deban aceptar conexiones remotas.

> [!WARNING]
> En un entorno real no sería recomendable reutilizar el usuario `postgres` para todo. En esta práctica se usa para simplificar el laboratorio, pero en un despliegue más serio sería mejor crear usuarios específicos con permisos limitados.

---

## 7. Comprobación de conexión entre nodos

Desde el nodo gateway se prueba la conexión hacia los nodos remotos.

Conexión al nodo history:

```bash
isard@gateway:~$ psql -h 192.168.1.16 -U postgres -d dvdrental
```

PostgreSQL solicita contraseña:

```text
Password for user postgres:
```

Si la conexión funciona, se entra en la consola:

```text
dvdrental=#
```

Se puede comprobar el servidor conectado ejecutando una consulta sencilla:

```sql
SELECT current_database(), current_user;
```

Ejemplo de salida:

```text
 current_database | current_user
------------------+--------------
 dvdrental        | postgres
```

Conexión al nodo current:

```bash
isard@gateway:~$ psql -h 192.168.1.17 -U postgres -d dvdrental
```

De nuevo, si la configuración es correcta, se accede a la base de datos remota.

Esta comprobación es importante porque valida la parte de red y permisos antes de configurar `postgres_fdw`.

---

## 8. Activación de postgres_fdw

En el nodo gateway se activa la extensión `postgres_fdw`.

```bash
isard@gateway:~$ sudo -u postgres psql -d dvdrental
```

Dentro de PostgreSQL:

```sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
```

Salida esperada:

```text
CREATE EXTENSION
```

También se puede comprobar que la extensión está instalada:

```sql
\dx
```

Ejemplo de salida:

```text
postgres_fdw | 1.1 | public | foreign-data wrapper for remote PostgreSQL servers
```

`postgres_fdw` permite que PostgreSQL actúe como cliente de otros servidores PostgreSQL, creando tablas locales que realmente apuntan a datos remotos.

---

## 9. Creación de servidores remotos

Desde el nodo gateway se definen los servidores remotos.

Servidor remoto para el nodo history:

```sql
CREATE SERVER history_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '192.168.1.16',
    dbname 'dvdrental',
    port '5432'
);
```

Salida esperada:

```text
CREATE SERVER
```

Servidor remoto para el nodo current:

```sql
CREATE SERVER current_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '192.168.1.17',
    dbname 'dvdrental',
    port '5432'
);
```

Salida esperada:

```text
CREATE SERVER
```

Se pueden listar los servidores remotos creados:

```sql
SELECT srvname, srvoptions
FROM pg_foreign_server;
```

Ejemplo de salida:

```text
    srvname     |                  srvoptions
----------------+-----------------------------------------------
 history_server | {host=192.168.1.16,dbname=dvdrental,port=5432}
 current_server | {host=192.168.1.17,dbname=dvdrental,port=5432}
```

---

## 10. Creación de user mappings

Después de crear los servidores remotos, se definen los user mappings. Esto indica con qué usuario y contraseña debe conectarse el nodo gateway a cada servidor remoto.

Mapping para history:

```sql
CREATE USER MAPPING FOR postgres
SERVER history_server
OPTIONS (
    user 'postgres',
    password 'CHANGE_ME_POSTGRES_PASSWORD'
);
```

Salida esperada:

```text
CREATE USER MAPPING
```

Mapping para current:

```sql
CREATE USER MAPPING FOR postgres
SERVER current_server
OPTIONS (
    user 'postgres',
    password 'CHANGE_ME_POSTGRES_PASSWORD'
);
```

Salida esperada:

```text
CREATE USER MAPPING
```

> [!IMPORTANT]
> En los scripts del repositorio la contraseña aparece como `CHANGE_ME_POSTGRES_PASSWORD`. Antes de ejecutar los scripts en un laboratorio real, hay que sustituir ese placeholder por la contraseña local correspondiente.

---

## 11. Creación de esquemas remotos

Para organizar las tablas foráneas de cada nodo, se crean esquemas separados en el gateway.

```sql
CREATE SCHEMA IF NOT EXISTS history_remote;
CREATE SCHEMA IF NOT EXISTS current_remote;
```

Salida esperada:

```text
CREATE SCHEMA
CREATE SCHEMA
```

La idea es no mezclar todas las tablas en `public`, sino separar visualmente qué tablas vienen de cada nodo.

```text
history_remote -> tablas remotas del nodo history
current_remote -> tablas remotas del nodo current
```

---

## 12. Importación de tablas foráneas

Una vez creados los servidores y los mappings, se importan tablas remotas.

Ejemplo para importar tablas desde el nodo history:

```sql
IMPORT FOREIGN SCHEMA public
LIMIT TO (actor, film, inventory, rental, payment)
FROM SERVER history_server
INTO history_remote;
```

Ejemplo para importar tablas desde el nodo current:

```sql
IMPORT FOREIGN SCHEMA public
LIMIT TO (actor, film, inventory, rental, payment)
FROM SERVER current_server
INTO current_remote;
```

Salida esperada:

```text
IMPORT FOREIGN SCHEMA
IMPORT FOREIGN SCHEMA
```

También se pueden crear foreign tables manualmente si se quiere controlar cada tabla una por una.

El objetivo de esta parte es que el gateway pueda consultar tablas que realmente están almacenadas en otros nodos.

---

## 13. Comprobación de foreign tables

Para comprobar que las tablas foráneas están disponibles:

```sql
SELECT foreign_table_schema, foreign_table_name, foreign_server_name
FROM information_schema.foreign_tables
ORDER BY foreign_table_schema, foreign_table_name;
```

Ejemplo de salida:

```text
 foreign_table_schema | foreign_table_name | foreign_server_name
----------------------+--------------------+---------------------
 current_remote       | actor              | current_server
 current_remote       | film               | current_server
 current_remote       | inventory          | current_server
 current_remote       | payment            | current_server
 current_remote       | rental             | current_server
 history_remote       | actor              | history_server
 history_remote       | film               | history_server
 history_remote       | inventory          | history_server
 history_remote       | payment            | history_server
 history_remote       | rental             | history_server
```

Esta consulta confirma que el nodo gateway reconoce tablas remotas procedentes de ambos servidores.

---

## 14. Consultas de validación

Una vez importadas las tablas foráneas, se realizan consultas de validación.

Recuento de registros en el nodo history:

```sql
SELECT 'history_remote.rental' AS source, COUNT(*) AS total
FROM history_remote.rental;
```

Ejemplo de salida:

```text
        source         | total
-----------------------+-------
 history_remote.rental | 16044
```

Recuento de registros en el nodo current:

```sql
SELECT 'current_remote.rental' AS source, COUNT(*) AS total
FROM current_remote.rental;
```

Ejemplo de salida:

```text
        source         | total
-----------------------+-------
 current_remote.rental | 16044
```

Comparación entre nodos:

```sql
SELECT 'history' AS node, COUNT(*) AS total
FROM history_remote.rental
UNION ALL
SELECT 'current' AS node, COUNT(*) AS total
FROM current_remote.rental;
```

Ejemplo de salida:

```text
  node   | total
---------+-------
 history | 16044
 current | 16044
```

Esta parte permite comprobar que las tablas remotas responden correctamente desde el gateway.

---

## 15. Consulta de ejemplo sobre datos remotos

También se puede lanzar una consulta de lectura sobre una tabla remota.

```sql
SELECT rental_id, rental_date, inventory_id, customer_id
FROM history_remote.rental
LIMIT 10;
```

Ejemplo de salida:

```text
 rental_id |     rental_date     | inventory_id | customer_id
-----------+---------------------+--------------+------------
         1 | 2005-05-24 22:53:30 |          367 |        130
         2 | 2005-05-24 22:54:33 |         1525 |        459
         3 | 2005-05-24 23:03:39 |         1711 |        408
```

Aunque la consulta se ejecuta desde el nodo gateway, los datos proceden del nodo remoto.

Este es el punto clave de la práctica: consultar datos distribuidos desde un servidor central.

---

## 16. Scripts SQL añadidos al repositorio

Para que el proyecto sea más claro y reutilizable, se ha añadido la carpeta `sql/`.

```text
sql/
|-- README.md
|-- 01_enable_fdw.sql
|-- 02_create_foreign_servers.sql
|-- 03_create_user_mappings.sql
|-- 04_import_foreign_schemas.sql
|-- 05_validation_queries.sql
```

Estos scripts separan el procedimiento en fases:

```text
01_enable_fdw.sql             -> activa postgres_fdw
02_create_foreign_servers.sql -> crea servidores remotos
03_create_user_mappings.sql   -> define credenciales de acceso remoto
04_import_foreign_schemas.sql -> importa tablas foráneas
05_validation_queries.sql     -> valida servidores, tablas y datos
```

> [!TIP]
> Separar los comandos SQL en scripts hace que el repositorio sea más útil como portfolio, porque ya no es solo una memoria escrita: también contiene una base reutilizable para reproducir parte del laboratorio.

---

## 17. Problemas y comprobaciones importantes

Durante una práctica de este tipo, los errores más habituales suelen estar relacionados con conexión o permisos.

Puntos revisados:

- PostgreSQL no escucha en la IP correcta.
- Falta una regla en `pg_hba.conf`.
- El gateway no tiene acceso a los nodos remotos.
- La contraseña del user mapping no coincide.
- El servidor remoto está mal definido.
- La base de datos remota no existe.
- La tabla remota no existe en el esquema indicado.
- El puerto 5432 no está accesible.
- No se ha reiniciado PostgreSQL después de cambiar la configuración.

Comandos útiles de comprobación:

```bash
sudo systemctl status postgresql
```

```bash
sudo ss -tulnp | grep 5432
```

```bash
psql -h 192.168.1.16 -U postgres -d dvdrental
```

```bash
psql -h 192.168.1.17 -U postgres -d dvdrental
```

---

## 18. Seguridad aplicada en la documentación

En la documentación original había referencias a contraseñas usadas durante el laboratorio.

Para publicar el repositorio, esas contraseñas se han sustituido por placeholders:

```text
CHANGE_ME_VM_PASSWORD
CHANGE_ME_POSTGRES_PASSWORD
```

Esto permite mantener el procedimiento técnico sin exponer credenciales reales.

> [!IMPORTANT]
> Si se reutilizan los scripts SQL, hay que sustituir los placeholders por valores locales antes de ejecutarlos. Nunca conviene subir contraseñas reales al repositorio.

---

## 19. Estructura final del repositorio

La estructura final queda organizada de esta forma:

```text
database-distribution-fragmentation/
|-- README.md
|-- .gitignore
|-- .gitattributes
|-- docs/
|   |-- memoria.md
|-- sql/
|   |-- README.md
|   |-- 01_enable_fdw.sql
|   |-- 02_create_foreign_servers.sql
|   |-- 03_create_user_mappings.sql
|   |-- 04_import_foreign_schemas.sql
|   |-- 05_validation_queries.sql
```

---

## 20. Valor técnico de la práctica

Esta práctica me ha servido para trabajar PostgreSQL desde una perspectiva más avanzada que una instalación local o cliente-servidor básica.

Los puntos más importantes que demuestra son:

- configuración de varios nodos PostgreSQL;
- conexión entre servidores;
- uso de `postgres_fdw`;
- creación de foreign servers;
- creación de user mappings;
- uso de foreign tables;
- consultas distribuidas;
- separación de datos entre nodos;
- documentación técnica del procedimiento;
- creación de scripts SQL reutilizables.

Aunque sigue siendo un laboratorio, se acerca más a un escenario real de administración de bases de datos distribuidas y ayuda a entender cómo PostgreSQL puede consultar información que físicamente se encuentra en otros servidores.
