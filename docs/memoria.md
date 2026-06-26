# Distribución y fragmentación de los datos

## 1. Preparación del entorno

Para esta práctica utilizaremos **tres máquinas virtuales** con Ubuntu Server y PostgreSQL ya configurado con la base de datos `dvdrental`. Opcionalmente, podemos incluir una cuarta máquina con entorno gráfico para poder hacer ssh con las demás máquinas y trabajar de forma mas cómoda.

### Máquina virtual: Gateway

* **Sistema operativo:** Ubuntu 24.02.1
* **Hostname:** gateway
* **Server name:** dosorio
* **Contraseña:** CHANGE_ME_VM_PASSWORD
* **IP:** 192.168.1.15/24
* **Software instalado:** PostgreSQL 18 + base de datos `dvdrental`

### Máquina virtual: History

* **Sistema operativo:** Ubuntu 24.02.1
* **Hostname:** history
* **Server name:** dosorio
* **Contraseña:** CHANGE_ME_VM_PASSWORD
* **IP:** 192.168.1.16/24
* **Software instalado:** PostgreSQL 18 + base de datos `dvdrental`

### Máquina virtual: Current

* **Sistema operativo:** Ubuntu 24.02.1
* **Hostname:** current
* **Server name:** dosorio
* **Contraseña:** CHANGE_ME_VM_PASSWORD
* **IP:** 192.168.1.17/24
* **Software instalado:** PostgreSQL 18 + base de datos `dvdrental`

---

## 2. Configuración de PostgreSQL en History y Current

### 2.1 Configuración en History

Editaremos el archivo principal de configuración:

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
```

Modificamos la siguiente línea para que PostgreSQL escuche en todas las interfaces:

```conf
listen_addresses = '*'
```

Editamos el archivo de control de acceso:

```bash
sudo nano /etc/postgresql/18/main/pg_hba.conf
```

Añadimos la siguiente línea para permitir el acceso desde Gateway:

```conf
host    dvdrental   postgres   192.168.1.15/32   scram-sha-256
```

Accedemos a PostgreSQL y asignar contraseña al usuario `postgres`:

```bash
sudo -u postgres psql
```

```sql
ALTER ROLE postgres WITH PASSWORD 'CHANGE_ME_POSTGRES_PASSWORD';
\q
```

hacemos un reinicio al servicio y comprobamos su estado:

```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

Resultado de `systemctl status postgresql`:

```text
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; pre>
     Active: active (exited) since Tue 2026-01-13 19:14:16 UTC; 22s ago
    Process: 8628 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
   Main PID: 8628 (code=exited, status=0/SUCCESS)
        CPU: 22ms

ene 13 19:14:16 dosorio systemd[1]: Starting postgresql.service - PostgreSQL >
ene 13 19:14:16 dosorio systemd[1]: Finished postgresql.service - PostgreSQL >
lines 1-9/9 (END)
```

---

### 2.2 Configuración en Current

Realizamos **exactamente el mismo procedimiento** que en la máquina History.

Editamos el archivo principal:

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
```

```conf
listen_addresses = '*'
```

Editamos `pg_hba.conf`:

```bash
sudo nano /etc/postgresql/18/main/pg_hba.conf
```

Añadimos al final:

```conf
host    dvdrental   postgres   192.168.1.15/32   scram-sha-256
```

Asignamos una contraseña al usuario `postgres`:

```bash
sudo -u postgres psql
```

```sql
ALTER ROLE postgres WITH PASSWORD 'CHANGE_ME_POSTGRES_PASSWORD';
\q
```

Reiniciamos y verificamos el servicio:

```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

Resultado de `systemctl status postgresql`:

```text
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; pre>
     Active: active (exited) since Tue 2026-01-13 19:22:33 UTC; 18s ago
    Process: 1417 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
   Main PID: 1417 (code=exited, status=0/SUCCESS)
        CPU: 18ms

ene 13 19:22:33 dosorio systemd[1]: Starting postgresql.service - PostgreSQL >
ene 13 19:22:33 dosorio systemd[1]: Finished postgresql.service - PostgreSQL >
lines 1-9/9 (END)
```

---

## 3. Preparación de los datos (borrados)

### 3.1 Servidor Current

En el servidor `current` se deben eliminar los pagos **anteriores al 2007-05-01**.

Accedemos a la base de datos:

```bash
sudo -u postgres psql -d dvdrental
```

Comprobamos cuántos registros cumplen la condición:

```sql
SELECT COUNT(*) FROM payment WHERE payment_date < '2007-05-01';
```

Resultado:

```text
 count
-------
 14414
(1 fila)
```

Eliminamos los registros:

```sql
DELETE FROM payment WHERE payment_date < '2007-05-01';
VACUUM (ANALYZE) payment;
```

Verificamos que se han eliminado correctamente:

```sql
SELECT COUNT(*) FROM payment WHERE payment_date < '2007-05-01';
```

Resultado:

```text
 count
-------
     0
(1 fila)
```

---

### 3.2 Servidor History

En el servidor `history` se deben eliminar los pagos **desde el 2007-05-01 en adelante**.

Accedemos a la base de datos:

```bash
sudo -u postgres psql -d dvdrental
```

Comprobamos los registros afectados:

```sql
SELECT COUNT(*) FROM payment WHERE payment_date >= '2007-05-01';
```

Resultado:

```text
 count
-------
 182
(1 fila)
```

Eliminamos los registros:

```sql
DELETE FROM payment WHERE payment_date >= '2007-05-01';
VACUUM (ANALYZE) payment;
```

Verificamos el borrado:

```sql
SELECT COUNT(*) FROM payment WHERE payment_date >= '2007-05-01';
```

Resultado:

```text
 count
-------
     0
(1 fila)
```

---

### 3.3 Servidor Gateway

En `gateway` se debe eliminar completamente la tabla `payment`, incluyendo su estructura.

Accedemos a la base de datos:

```bash
sudo -u postgres psql -d dvdrental
```

Eliminamos la tabla:

```sql
DROP TABLE IF EXISTS public.payment CASCADE;
```

Resultado:

```text
NOTICE:  eliminando además 2 objetos más
DETALLE:  eliminando además vista sales_by_film_category
eliminando además vista sales_by_store
DROP TABLE
```

---

## 4. Configuración de Foreign Data Wrapper (FDW) en Gateway

Una vez eliminada, nuestro objetivo es importar tablas foráneas de las otras dos máquinas a la de gateway, para ello debemos usar una extensión de postgresql que permitirá el enlace entre el servidor que queremos usar y las otras bases de datos que tenemos en las máquinas History y Current. La extensión que vamos a utilizar es FDW (Foreign Data Wrapper).

### 4.1 Activar la extensión FDW

Para ponerlo en marcha, en la máquina Gateaway:

```sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
```

Resultado:

```text
CREATE EXTENSION
```

### 4.2 Crear los servidores remotos

Una vez creada la extensión, crearemos las conexiones con los otros postgresql con:

```sql
CREATE SERVER srv_history
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host '192.168.1.16', dbname 'dvdrental', port '5432');
```

Resultado:

```text
CREATE SERVER
```

```sql
CREATE SERVER srv_current
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host '192.168.1.17', dbname 'dvdrental', port '5432');
```

Resultado:

```text
CREATE SERVER
```

### 4.3 Crear los user mappings

Seguidamente, crearemos el usuario remoto con el que podremos entrar al servidor fdw, que es donde tendremos la tabla combinada.
Para simplificar el laboratorio se utiliza el usuario postgres. La contraseña se documenta mediante el placeholder CHANGE_ME_POSTGRES_PASSWORD.


```sql
CREATE USER MAPPING FOR postgres
SERVER srv_history
OPTIONS (user 'postgres', password 'CHANGE_ME_POSTGRES_PASSWORD');
```

Resultado:

```text
CREATE USER MAPPING
```

```sql
CREATE USER MAPPING FOR postgres
SERVER srv_current
OPTIONS (user 'postgres', password 'CHANGE_ME_POSTGRES_PASSWORD');
```

Resultado:

```text
CREATE USER MAPPING
```

---

## 5. Creación de la tabla padre `payment_complete`

Por otra parte, también en la máquina **Gateway** crearemos una tabla vacía llamada payment_complete, que actuará como tabla padre.

```sql
CREATE TABLE payment_complete (
  payment_id integer,
  customer_id smallint,
  staff_id smallint,
  rental_id integer,
  amount numeric(5,2),
  payment_date timestamp
);
```

Resultado:

```text
CREATE TABLE
```

Esta tabla define la estructura común y actuará como tabla padre.

---

## 6. Creación de tablas foráneas heredadas

El siguiente paso, será la creación de las tablas foráneas heredadas
En lugar de importar el esquema completo, crearemos directamente las tablas foráneas, indicando:
El servidor remoto
La tabla remota (payment)
La herencia desde payment_complete

### 6.1 Tabla foránea de pagos históricos

```sql
CREATE FOREIGN TABLE payment_history (
  payment_id integer,
  customer_id smallint,
  staff_id smallint,
  rental_id integer,
  amount numeric(5,2),
  payment_date timestamp
)
INHERITS (payment_complete)
SERVER srv_history
OPTIONS (schema_name 'public', table_name 'payment');
```

Resultado:

```text
NOTICE:  mezclando la columna «payment_id» con la definición heredada
NOTICE:  mezclando la columna «customer_id» con la definición heredada
NOTICE:  mezclando la columna «staff_id» con la definición heredada
NOTICE:  mezclando la columna «rental_id» con la definición heredada
NOTICE:  mezclando la columna «amount» con la definición heredada
NOTICE:  mezclando la columna «payment_date» con la definición heredada
CREATE FOREIGN TABLE
```

Esta tabla representa los pagos **anteriores al 2007-05-01** almacenados en el servidor `history`.

---

### 6.2 Tabla foránea de pagos actuales

```sql
CREATE FOREIGN TABLE payment_current (
  payment_id integer,
  customer_id smallint,
  staff_id smallint,
  rental_id integer,
  amount numeric(5,2),
  payment_date timestamp
)
INHERITS (payment_complete)
SERVER srv_current
OPTIONS (schema_name 'public', table_name 'payment');
```

Resultado:

```text
NOTICE:  mezclando la columna «payment_id» con la definición heredada
NOTICE:  mezclando la columna «customer_id» con la definición heredada
NOTICE:  mezclando la columna «staff_id» con la definición heredada
NOTICE:  mezclando la columna «rental_id» con la definición heredada
NOTICE:  mezclando la columna «amount» con la definición heredada
NOTICE:  mezclando la columna «payment_date» con la definición heredada
CREATE FOREIGN TABLE
```

Esta tabla representa los pagos **actuales** almacenados en el servidor `current`.

---

## 7. Verificación del acceso unificado

Una vez hecha la herencia y la creación de un acceso unificado a los datos, podemos realizar cualquier consulta sobre payment_complete y esta accedera automáticamente a payment_history y payment_current sin necesidad de especificarlas explícitamente.

Como por ejemplo una consulta total de pagos:

```sql
SELECT COUNT(*) FROM payment_complete;
```

Resultado:

```text
 count
-------
 14596
(1 fila)
```

De esta manera, postgreSQL distribuye internamente la consulta entre los servidores remotos.
Ahora podemos hacer una verificación de la fragmentación directamente comprobando los registros por rangos de fecha:

```sql
SELECT COUNT(*) FROM payment_complete
WHERE payment_date < '2007-05-01';
```

Resultado:

```text
 count
-------
 14414
(1 fila)
```

```sql
SELECT COUNT(*) FROM payment_complete
WHERE payment_date >= '2007-05-01';
```

Resultado:

```text
 count
-------
 182
(1 fila)
```

Los resultados confirman que los datos están correctamente fragmentados y accesibles de forma transparente.

---

## 8. Conclusión

Mediante el uso de **Foreign Data Wrapper** y **herencia de tablas**, se ha implementado una solución de **fragmentación horizontal** que permite:

* Separar datos históricos y actuales
* Mejorar el rendimiento del sistema
* Mantener un punto de acceso único para las consultas
