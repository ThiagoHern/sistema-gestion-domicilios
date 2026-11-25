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
   - El lanzador arranca `app\sistema-domicilios-1.0.0.jar` y abre automáticamente **`http://localhost:8080`**.
3. **Probar con Postman:**
   - Importa [`postman/Sistema_Domicilios_Cali.postman_collection.json`](postman/Sistema_Domicilios_Cali.postman_collection.json) en Postman (o corre `postman collection run postman\Sistema_Domicilios_Cali.postman_collection.json` en PowerShell).

*(Opcional — ejecutar desde el código fuente sin instalar Maven: `.\mvnw.cmd spring-boot:run`)*

---

## Estructura del repositorio
- `ejecutar.bat` — Lanzador de inicio rápido para Windows.
- `app/sistema-domicilios-1.0.0.jar` — Backend Spring Boot 3.3.5 + interfaz web ya compilados.
- `sql/` — `01_BD_SistemaDomicilios_Final.sql` (DDL, 2 funciones, 3 vistas, 5 triggers, 3 SPs ACID y datos en Cali) y `02_Consultas_y_Pruebas_Integridad.sql`.
- `src/` — Código fuente Java 17 (`DomiciliosController`, `DomiciliosService`), interfaz web (`static/index.html`) y pruebas unitarias.
- `postman/` — Colección de pruebas REST con aserciones automáticas (`pm.test`).
- `docs/` — Informe final en normas APA 7 (`Documento_Final_Proyecto_Integrador_SGBD_UAO.docx`).
- `wiki/` — Documentación técnica en Markdown.
