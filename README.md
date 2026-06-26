# Database Distribution and Fragmentation

Práctica de diseño y configuración de un entorno de bases de datos distribuidas utilizando PostgreSQL.

El proyecto trabaja la idea de repartir una base de datos en varios nodos, configurando servidores PostgreSQL independientes y utilizando `postgres_fdw` para consultar información remota desde un nodo principal.

> [!NOTE]
> Este repositorio está planteado como práctica técnica de bases de datos distribuidas. No es un despliegue de producción, sino un laboratorio para entender fragmentación, conexión entre nodos y consultas distribuidas.

## Objetivo

El objetivo de la práctica es simular un entorno distribuido con varios servidores PostgreSQL, donde cada nodo almacena una parte de la información y el nodo principal puede acceder a los datos mediante foreign tables.

## Entorno utilizado

- PostgreSQL
- Ubuntu Server
- Base de datos `dvdrental`
- Extensión `postgres_fdw`
- Varios nodos PostgreSQL en red
- SQL
- SSH
- Git y GitHub

## Arquitectura del laboratorio

El laboratorio utiliza tres máquinas PostgreSQL:

- Nodo principal: `192.168.1.15`
- Nodo remoto 1: `192.168.1.16`
- Nodo remoto 2: `192.168.1.17`

La idea principal es separar datos entre nodos y acceder a ellos desde el servidor principal mediante conexiones remotas configuradas en PostgreSQL.

## Qué se trabaja

En esta práctica se documenta:

- Preparación de varios servidores PostgreSQL.
- Configuración de acceso remoto entre nodos.
- Uso de la base de datos `dvdrental`.
- Creación de la extensión `postgres_fdw`.
- Definición de foreign servers.
- Creación de user mappings.
- Creación de foreign tables.
- Consultas distribuidas desde un nodo principal.
- Revisión de permisos y conexión entre servidores.

> [!TIP]
> Esta práctica ayuda a entender de forma sencilla cómo una base de datos puede dividirse entre varios servidores y consultarse desde un punto central.

## Estructura del repositorio

~~~text
database-distribution-fragmentation/
|-- README.md
|-- .gitignore
|-- .gitattributes
|-- docs/
|   |-- memoria.md
~~~

## Documentación completa

La memoria técnica completa, con comandos, configuración de nodos, consultas SQL y explicación del procedimiento, está en:

~~~text
docs/memoria.md
~~~
