# Database Distribution and Fragmentation

Laboratorio de bases de datos distribuidas utilizando PostgreSQL y `postgres_fdw`.

En este proyecto he trabajado un escenario con varios servidores PostgreSQL conectados entre sí, donde un nodo principal puede consultar datos almacenados en otros nodos remotos mediante foreign tables.

La práctica parte de la base de datos `dvdrental` y se centra en entender cómo se puede fragmentar o repartir información entre diferentes máquinas, manteniendo la posibilidad de consultarla desde un punto central.

> [!NOTE]
> Este repositorio está planteado como laboratorio técnico. No es un despliegue de producción, sino una práctica para entender distribución de datos, conexión entre nodos PostgreSQL y consultas remotas.

## Qué problema se trabaja

En una instalación normal, una base de datos suele estar en un único servidor. En esta práctica se plantea un escenario diferente: separar información en distintos nodos y acceder a ella desde un servidor principal.

La idea es simular un entorno donde parte de los datos están en un nodo y otra parte en otro, pero el nodo principal puede consultarlos usando PostgreSQL como punto de acceso centralizado.

## Arquitectura del laboratorio

El laboratorio utiliza tres máquinas PostgreSQL:

* Nodo principal / gateway: `192.168.1.15`
* Nodo remoto history: `192.168.1.16`
* Nodo remoto current: `192.168.1.17`

El nodo principal actúa como punto de consulta. Los nodos remotos almacenan parte de la información y se conectan mediante `postgres_fdw`.

Flujo general:

* El nodo principal no almacena toda la información localmente.
* Los nodos remotos contienen datos separados.
* Desde el nodo principal se definen servidores remotos.
* Se crean user mappings para permitir la autenticación.
* Se importan o definen foreign tables.
* Las consultas se lanzan desde el nodo principal, aunque parte de los datos estén en otros servidores.

> [!TIP]
> Antes de trabajar con `postgres_fdw`, es importante comprobar que los nodos se ven por red y que PostgreSQL permite conexiones remotas entre ellos. Si la conexión básica falla, las foreign tables tampoco funcionarán.

## Tecnologías utilizadas

* PostgreSQL
* Ubuntu Server
* Base de datos `dvdrental`
* Extensión `postgres_fdw`
* SQL
* SSH
* Configuración de acceso remoto
* Foreign servers
* User mappings
* Foreign tables
* Git y GitHub

## Qué se ha trabajado

En la memoria técnica se documenta el proceso completo:

* Preparación de varios servidores PostgreSQL.
* Configuración de IPs y acceso entre nodos.
* Ajustes en `postgresql.conf`.
* Ajustes en `pg_hba.conf`.
* Asignación de contraseña al usuario `postgres`.
* Comprobación de conexiones entre máquinas.
* Creación de la extensión `postgres_fdw`.
* Creación de servidores remotos desde el nodo principal.
* Creación de user mappings.
* Definición de foreign tables.
* Consultas distribuidas desde el nodo gateway.
* Comprobación de resultados mediante consultas SQL.

## Fragmentación y distribución

La práctica trabaja el concepto de distribución de datos desde un enfoque práctico.

En lugar de quedarse solo en la teoría, se configura un entorno donde el nodo principal puede acceder a tablas o partes de tablas que realmente se encuentran en otros servidores PostgreSQL.

Esto permite entender mejor conceptos como:

* Fragmentación de datos.
* Distribución entre nodos.
* Acceso remoto desde PostgreSQL.
* Consultas sobre datos externos.
* Separación lógica entre servidores.
* Uso de un nodo central como punto de consulta.

## Seguridad y credenciales

En mi entorno local se usaron contraseñas para las máquinas y para PostgreSQL, pero en el repositorio se han sustituido por placeholders.

Ejemplos utilizados en la documentación:

* `CHANGE_ME_VM_PASSWORD`
* `CHANGE_ME_POSTGRES_PASSWORD`

> [!IMPORTANT]
> Las credenciales reales no forman parte del repositorio. La documentación mantiene el proceso técnico, pero no deja contraseñas personales publicadas.

## Estructura del repositorio

* `README.md`: presentación general del proyecto.
* `docs/memoria.md`: documentación técnica completa.
* `.gitignore`: exclusión de archivos temporales o locales.
* `.gitattributes`: normalización de saltos de línea.

## Documentación completa

La memoria técnica completa, con comandos, configuración de nodos, consultas SQL y comprobaciones, está en:

`docs/memoria.md`

## Valor técnico del proyecto

Este proyecto es útil para reforzar conocimientos de bases de datos más allá de una instalación local básica.

Trabaja una parte importante de PostgreSQL: la conexión entre servidores y el uso de datos remotos mediante `postgres_fdw`.

## Diagrama de arquitectura

~~~mermaid
flowchart LR
    A[Gateway PostgreSQL<br>192.168.1.15] -->|postgres_fdw| B[History node<br>192.168.1.16]
    A -->|postgres_fdw| C[Current node<br>192.168.1.17]

    B --> D[(Fragmento de datos)]
    C --> E[(Fragmento de datos)]
~~~

El nodo principal actúa como punto central de consulta. Los nodos remotos mantienen parte de la información y se exponen al gateway mediante foreign tables.

## Scripts SQL reproducibles

Además de la memoria técnica, el repositorio incluye una carpeta `sql/` con scripts separados por fases.

~~~text
sql/
|-- README.md
|-- 01_enable_fdw.sql
|-- 02_create_foreign_servers.sql
|-- 03_create_user_mappings.sql
|-- 04_import_foreign_schemas.sql
|-- 05_validation_queries.sql
~~~

Estos scripts permiten consultar de forma más clara qué pasos son necesarios para preparar el nodo gateway, conectar con los nodos remotos e importar tablas externas mediante `postgres_fdw`.

> [!IMPORTANT]
> Los scripts usan placeholders para las contraseñas. Antes de ejecutarlos, hay que sustituir `CHANGE_ME_POSTGRES_PASSWORD` por la contraseña local del laboratorio.
