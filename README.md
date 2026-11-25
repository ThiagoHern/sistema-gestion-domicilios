# Sistema de Gestión de Operaciones de Domicilios (Cali)

Proyecto Integrador — **Bases de Datos 1** | Universidad Autónoma de Occidente (UAO).

---

## Cómo ejecutar en Windows (3 pasos)

Requisitos: **Java 17+** y **MySQL Server 8.0** (servicio `MySQL80` iniciado).

1. **Encender MySQL 8.0:**
   - Abre **Servicios** de Windows (`Win + R` → `services.msc`), busca **`MySQL80`** y haz clic en **Iniciar**.
2. **Ejecutar el sistema:**
   - Haz doble clic en **`ejecutar.bat`**.
   - Ingresa tu usuario de MySQL (`root` por defecto) y tu contraseña (`root` por defecto, o escribe `VACIO` si no usa clave).
   - Responde **`s`** cuando te pregunte si deseas cargar `sql\01_BD_SistemaDomicilios_Final.sql` (o ejecútalo desde MySQL Workbench con `Ctrl + Shift + Enter`).
   - El lanzador arranca `sistema-domicilios-1.0.0.jar` y abre automáticamente **`http://localhost:8080`**.
3. **Probar con Postman:**
   - Importa [`docs/Sistema_Domicilios_Cali.postman_collection.json`](docs/Sistema_Domicilios_Cali.postman_collection.json) en Postman, o ejecuta con Postman CLI:
     ```powershell
     postman collection run docs\Sistema_Domicilios_Cali.postman_collection.json
     ```

*(Opcional — ejecutar desde código fuente sin instalar Maven: `.\mvnw.cmd spring-boot:run`)*

---

## Estructura del repositorio
- `docs/` — Informe final en normas APA 7 (`Documento_Final_Proyecto_Integrador_SGBD_UAO.docx`) y colección de Postman (`Sistema_Domicilios_Cali.postman_collection.json`).
- `sql/` — `01_BD_SistemaDomicilios_Final.sql` (DDL, 2 funciones, 3 vistas, 5 triggers, 3 SPs ACID y datos en Cali) y `02_Consultas_y_Pruebas_Integridad.sql`.
- `src/` — Código fuente Java 17 (`DomiciliosController`, `DomiciliosService`), interfaz web (`static/index.html`) y pruebas unitarias.
- `ejecutar.bat` y `sistema-domicilios-1.0.0.jar` — Lanzador y aplicación Spring Boot lista para ejecutar.
- `pom.xml`, `mvnw.cmd` y `.mvn/` — Configuración de Maven Wrapper para Windows.
