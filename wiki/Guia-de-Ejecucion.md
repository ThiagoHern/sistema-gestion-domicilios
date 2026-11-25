# Guía de Ejecución Rápida (Paquete Local Autocontenido)

Esta carpeta incluye todo lo necesario para ejecutar el proyecto directamente sin depender de repositorios externos ni de tener Maven instalado.

## 1. Ejecución en Windows / Linux / macOS (Recomendada)
1. Asegúrate de tener **Java 17+** y **MySQL Server 8.0** en ejecución.
2. Carga la base de datos en **MySQL Workbench**:
   * Abre `sql/01_BD_SistemaDomicilios_Final.sql` y ejecuta todo el script (`Ctrl + Shift + Enter`).
   * *(Opcional)* También puedes dejar que el lanzador cargue el script automáticamente.
3. Inicia el sistema:
   * **Windows:** haz doble clic en `ejecutar.bat`.
   * **Linux / macOS:** ejecuta `chmod +x ejecutar.sh && ./ejecutar.sh`.
   * Ingresa tu usuario de MySQL (`root` por defecto) y tu contraseña (`root` por defecto, o escribe `VACIO` si no usa contraseña).
4. El lanzador ejecuta `app/sistema-domicilios-1.0.0.jar` y abre automáticamente **http://localhost:8080** en el navegador.

## 2. Ejecución desde Código Fuente (Maven Wrapper)
Si deseas compilar o ejecutar directamente desde los archivos `.java`:
* **Windows:** `.\mvnw.cmd spring-boot:run`
* **Linux / macOS:** `./mvnw spring-boot:run`

## 3. Ejecución con Docker Compose
Si tienes Docker Desktop instalado (levanta MySQL 8.0 con datos cargados + Spring Boot):
```bash
docker compose up --build
```
Luego abre **http://localhost:8080**.
