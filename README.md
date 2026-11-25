# Sistema de Gestión de Operaciones de Domicilios (Cali)

Proyecto Integrador — **Bases de Datos 1** | Universidad Autónoma de Occidente (UAO).

---

## Formas de ejecución (elige la más cómoda)

### Opción 1: Ejecutar en la nube en 1 clic (sin instalar nada)
Abre el entorno completo en GitHub Codespaces (**MySQL 8.0 + datos cargados + Spring Boot 3.3 + Interfaz Web**):

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ThiagoHern/sistema-gestion-domicilios?quickstart=1)

> Al terminar de iniciar (1–2 minutos), abre la pestaña **Ports** y haz clic en el ícono de globo del puerto **8080** para ver la aplicación web o probar la API con Postman.

### Opción 2: Ejecución local con MySQL Workbench (Windows / Linux / Mac)
Requisitos: **Java 17+** y **MySQL Server 8.0** (no necesitas instalar Maven porque el repositorio incluye `./mvnw` y `mvnw.cmd`).

1. Abre **MySQL Workbench** y ejecuta completo el script:
   - [`sql/01_BD_SistemaDomicilios_Final.sql`](sql/01_BD_SistemaDomicilios_Final.sql) (`Ctrl + Shift + Enter`).
   - *(Opcional)* Ejecuta consultas y pruebas SQL desde [`sql/02_Consultas_y_Pruebas_Integridad.sql`](sql/02_Consultas_y_Pruebas_Integridad.sql).
2. Ejecuta el lanzador:
   - **Windows:** doble clic o terminal en `ejecutar.bat`
   - **Linux/Mac:** `./ejecutar.sh`
   - O manualmente: `.\mvnw.cmd spring-boot:run`
3. Abre en tu navegador: **http://localhost:8080**

### Opción 3: Docker Compose en 1 comando
```bash
docker compose up --build
```
Inicia MySQL 8.0 con la base de datos cargada automáticamente y la aplicación Spring Boot en `http://localhost:8080`.

---

## Qué incluye el sistema
- **Base de datos MySQL 8 (`sql/01_BD_SistemaDomicilios_Final.sql`):**
  - 9 tablas normalizadas hasta 3FN/BCNF (`Usuario`, `Cliente`, `Domiciliario`, `Barrio`, `DireccionEntrega`, `EstablecimientoAliado`, `SolicitudDomicilio`, `Incidente`, `AuditoriaSistema`).
  - Restricciones `CHECK` (`ck_monto_no_negativo`, `ck_lugar_recogida`, `ck_asignacion`, `ck_estado_domiciliario`) y clave foránea compuesta `(idDireccion, numeroIdentificacionCliente)`.
  - **3 Vistas:** `vw_solicitudes_activas_cali`, `vw_resumen_domiciliarios`, `vw_resumen_establecimientos`.
  - **2 Funciones:** `fn_calcular_tarifa_entrega`, `fn_contar_incidentes_solicitud`.
  - **5 Triggers:** `trg_validar_incidente_fecha`, `trg_validar_domiciliario_activo_ins`, `trg_validar_domiciliario_activo_upd`, `trg_auditar_incidente`, `trg_auditar_cambio_estado_solicitud`.
  - **3 Stored Procedures ACID:** `sp_registrar_solicitud`, `sp_asignar_domiciliario`, `sp_actualizar_estado_solicitud`.
- **Backend Spring Boot 3.3.5 + Interfaz Web (`src/main/resources/static/index.html`):**
  - API REST completa en `/api/*` con `JdbcTemplate` y `Prepared Statements`.
  - Panel web con KPIs, gestión de solicitudes, incidentes, auditoría, entidades, vistas analíticas y **Laboratorio de Pruebas de Reglas de Negocio** en 1 clic.
- **Pruebas en Postman:**
  - Importa [`postman/Sistema_Domicilios_Cali.postman_collection.json`](postman/Sistema_Domicilios_Cali.postman_collection.json) en Postman (incluye pruebas positivas y negativas con scripts `pm.test`).

---

## Documentación y GitHub Wiki
Consulta la **[GitHub Wiki](https://github.com/ThiagoHern/sistema-gestion-domicilios/wiki)** (también respaldada en [`wiki/`](wiki/)) para ver:
- Modelado MEER / MR y Normalización (1FN a 5FN / BCNF)
- Catálogo de Objetos Procedimentales SQL
- Endpoints REST y Casos de Prueba en Postman
- Guía paso a paso de ejecución
