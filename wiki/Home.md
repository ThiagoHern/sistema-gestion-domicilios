# Wiki — Sistema de Gestión de Operaciones de Domicilios (Cali)

Documentación técnica del proyecto integrador de **Bases de Datos 1** (Universidad Autónoma de Occidente).

## Arquitectura del Sistema
* **Base de Datos:** MySQL 8.0 (`InnoDB`, `utf8mb4`), normalizada hasta 3FN/BCNF con restricciones `CHECK`, FK compuesta, 3 Vistas, 2 Funciones, 3 Triggers y 3 Procedimientos Almacenados transaccionales (`ACID`).
* **Backend:** Spring Boot 3.3 (Java 17) con arquitectura en capas (`Controller` -> `Service/DAO` -> `MySQL`) utilizando `JdbcTemplate` y consultas parametrizadas (`Prepared Statements`).
* **Interfaz Gráfica:** Aplicación web integrada en `src/main/resources/static/index.html` servida directamente por Spring Boot.
* **Despliegue en 1 clic:** Configurado con `.devcontainer` para ejecutarse en **GitHub Codespaces** sin instalaciones locales.

## Navegación
* [[API-REST-y-Pruebas-Postman]]
