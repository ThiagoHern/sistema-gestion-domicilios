# Wiki — Sistema de Gestión de Operaciones de Domicilios (Cali)

Documentación técnica del Proyecto Integrador de **Bases de Datos 1** — **Universidad Autónoma de Occidente (UAO)**.

## Resumen de la Solución
* **Base de Datos:** MySQL 8.0 (`InnoDB`, `utf8mb4_unicode_ci`), esquema normalizado hasta 3FN/BCNF con 9 tablas, restricciones `CHECK`, clave foránea compuesta `(idDireccion, numeroIdentificacionCliente)`, **3 Vistas**, **2 Funciones**, **5 Triggers** y **3 Procedimientos Almacenados transaccionales (`ACID`)**.
* **Backend:** Spring Boot 3.3.5 (Java 17) con arquitectura en capas (`Controller` → `Service / DAO` → `MySQL 8`) utilizando `JdbcTemplate`, `CallableStatement` y consultas parametrizadas (`Prepared Statements`).
* **Interfaz Visual:** Aplicación web SPA integrada en `src/main/resources/static/index.html`, servida automáticamente en `http://localhost:8080`, con tablero KPI y **Laboratorio de Pruebas de Reglas de Negocio**.
* **Ejecución en 1 clic:** Entorno listo para **GitHub Codespaces** (`.devcontainer`), **Docker Compose** y scripts locales (`ejecutar.bat` / `ejecutar.sh`) con **Maven Wrapper (`mvnw`)**.

## Índice de la Wiki
* [[Modelado-y-Normalizacion]] — MEER, Modelo Relacional, reglas RN-01 a RN-07 y justificación 1FN–5FN/BCNF.
* [[Objetos-Procedimentales-SQL]] — Vistas, funciones, triggers y procedimientos almacenados ACID.
* [[API-REST-y-Pruebas-Postman]] — Catálogo de endpoints Spring Boot y colección de pruebas Postman.
* [[Guia-de-Ejecucion]] — Instrucciones paso a paso para Codespaces, MySQL Workbench y Docker.
