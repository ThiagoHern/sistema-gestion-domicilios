# Sistema de Gestión de Operaciones de Domicilios (Cali)

Proyecto Integrador — **Bases de Datos 1** | Universidad Autónoma de Occidente (UAO).

Carpeta autocontenida con todo lo necesario para ejecutar la base de datos en **MySQL 8.0**, el backend en **Spring Boot 3.3.5**, la interfaz web, las pruebas en **Postman** y la documentación técnica.

---

## Ejecución rápida desde esta carpeta (sin instalar Maven)

Requisitos: **Java 17+** y **MySQL Server 8.0**.

1. **Cargar la base de datos en MySQL:**
   - Abre **MySQL Workbench**, carga [`sql/01_BD_SistemaDomicilios_Final.sql`](sql/01_BD_SistemaDomicilios_Final.sql) y presiona **`Ctrl + Shift + Enter`** (o permite que `ejecutar.bat` / `ejecutar.sh` la cargue por ti).
   - *(Opcional)* Ejecuta las consultas y pruebas de integridad desde [`sql/02_Consultas_y_Pruebas_Integridad.sql`](sql/02_Consultas_y_Pruebas_Integridad.sql).
2. **Iniciar el sistema:**
   - **Windows:** doble clic en `ejecutar.bat`
   - **Linux / macOS:** `chmod +x ejecutar.sh && ./ejecutar.sh`
   - El lanzador arranca directamente el ejecutable precompilado [`app/sistema-domicilios-1.0.0.jar`](app/sistema-domicilios-1.0.0.jar) y abre **http://localhost:8080** en el navegador.
3. **Ejecución alternativa desde código fuente o Docker:**
   - Código fuente (Maven Wrapper): `.\mvnw.cmd spring-boot:run` (Windows) o `./mvnw spring-boot:run` (Linux/Mac).
   - Docker Desktop (incluye MySQL 8 + Spring Boot): `docker compose up --build`.

---

## Qué incluye el sistema
- **Base de datos MySQL 8 (`sql/01_BD_SistemaDomicilios_Final.sql`):**
  - 9 tablas normalizadas hasta 3FN/BCNF (`Usuario`, `Cliente`, `Domiciliario`, `Barrio`, `DireccionEntrega`, `EstablecimientoAliado`, `SolicitudDomicilio`, `Incidente`, `AuditoriaSistema`).
  - Restricciones `CHECK` (`ck_monto_no_negativo`, `ck_lugar_recogida`, `ck_asignacion`, `ck_estado_domiciliario`) y clave foránea compuesta `(idDireccion, numeroIdentificacionCliente)`.
  - **2 Funciones:** `fn_calcular_tarifa_entrega`, `fn_contar_incidentes_solicitud`.
  - **3 Vistas:** `vw_solicitudes_activas_cali`, `vw_resumen_domiciliarios`, `vw_resumen_establecimientos`.
  - **5 Triggers:** `trg_validar_incidente_fecha`, `trg_validar_domiciliario_activo_ins`, `trg_validar_domiciliario_activo_upd`, `trg_auditar_incidente`, `trg_auditar_cambio_estado_solicitud`.
  - **3 Stored Procedures ACID:** `sp_registrar_solicitud`, `sp_asignar_domiciliario`, `sp_actualizar_estado_solicitud`.
- **Backend Spring Boot 3.3.5 + Interfaz Web (`src/main/resources/static/index.html`):**
  - API REST completa en `/api/*` con `JdbcTemplate` y `Prepared Statements`.
  - Interfaz operativa sobria servida en `http://localhost:8080` con gestión de solicitudes, incidentes, bitácora de auditoría, directorio de entidades, vistas SQL y pestaña **Pruebas SQL** para verificar rechazos de reglas de negocio en vivo.
- **Pruebas en Postman:**
  - Importa [`postman/Sistema_Domicilios_Cali.postman_collection.json`](postman/Sistema_Domicilios_Cali.postman_collection.json) en Postman (6 carpetas con aserciones automatizadas `pm.test`).

---

## Documentación técnica local (`wiki/`)
Consulta la carpeta [`wiki/`](wiki/) y el archivo `LEEME_COMO_EJECUTAR.txt` para ver:
- Modelado MEER / MR y Normalización (`1FN` a `5FN` / `BCNF`)
- Catálogo de Objetos Procedimentales SQL
- Endpoints REST y Casos de Prueba en Postman
- Guía paso a paso de ejecución
