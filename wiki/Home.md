# Wiki — Sistema de Gestión de Operaciones de Domicilios (Cali)

Documentación técnica del Proyecto Integrador de **Bases de Datos 1** — **Universidad Autónoma de Occidente (UAO)**.

## Resumen de la Solución
* **Base de Datos:** MySQL 8.0 (`InnoDB`, `utf8mb4_unicode_ci`), esquema normalizado hasta 3FN/BCNF con 9 tablas, restricciones `CHECK`, clave foránea compuesta `(idDireccion, numeroIdentificacionCliente)`, **2 Funciones**, **3 Vistas**, **5 Triggers** y **3 Procedimientos Almacenados transaccionales (`ACID`)**.
* **Backend:** Spring Boot 3.3.5 (Java 17) con arquitectura en capas (`Controller` → `Service / DAO` → `MySQL 8`) utilizando `JdbcTemplate`, `CallableStatement` y consultas parametrizadas (`Prepared Statements`).
* **Interfaz Visual:** Aplicación web SPA integrada en `src/main/resources/static/index.html`, servida automáticamente en `http://localhost:8080`, con gestión operativa y pestaña **Pruebas SQL** para validar reglas de negocio en vivo.
* **Ejecución en Windows:** Incluye el ejecutable precompilado `app\sistema-domicilios-1.0.0.jar`, lanzador `ejecutar.bat`, colección Postman y **Maven Wrapper (`mvnw.cmd`)**.

## Índice de la Documentación
* [[Modelado-y-Normalizacion]] — MEER, Modelo Relacional, reglas RN-01 a RN-07 y justificación 1FN–5FN/BCNF.
* [[Objetos-Procedimentales-SQL]] — Funciones, vistas, triggers y procedimientos almacenados ACID.
* [[API-REST-y-Pruebas-Postman]] — Catálogo de endpoints Spring Boot y colección de pruebas Postman.
* [[Guia-de-Ejecucion]] — Instrucciones paso a paso para Windows (`ejecutar.bat`, MySQL Workbench y Postman).
