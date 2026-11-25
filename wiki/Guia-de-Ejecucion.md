# Guía de Ejecución Rápida

## 1. GitHub Codespaces (1 clic, sin instalaciones)
1. Haz clic en **Code → Codespaces → Create codespace on main** en el repositorio `https://github.com/ThiagoHern/sistema-gestion-domicilios`.
2. El contenedor levanta **MySQL 8.0**, carga `sql/01_BD_SistemaDomicilios_Final.sql` automáticamente y arranca Spring Boot en el puerto `8080`.
3. Abre la pestaña **Ports** y haz clic en el ícono de globo del puerto `8080`.

## 2. Ejecución Local con MySQL Workbench
1. Asegúrate de tener **Java 17+** y **MySQL Server 8.0** ejecutándose.
2. En **MySQL Workbench**, abre `sql/01_BD_SistemaDomicilios_Final.sql` y presiona **Ctrl + Shift + Enter** para crear la base de datos, tablas, funciones, vistas, triggers, procedimientos y datos semilla.
3. Ejecuta el proyecto:
   * **Windows:** ejecuta `ejecutar.bat` (puedes dejar usuario `root` y contraseña `root` o ingresar tu clave local).
   * **Linux/macOS:** ejecuta `chmod +x ejecutar.sh && ./ejecutar.sh`.
   * **Manual:** `.\mvnw.cmd spring-boot:run` (Windows) o `./mvnw spring-boot:run` (Linux/Mac).
4. Abre **http://localhost:8080** en tu navegador.

## 3. Docker Compose
Si tienes Docker Desktop instalado:
```bash
docker compose up --build
```
Luego abre **http://localhost:8080**.
