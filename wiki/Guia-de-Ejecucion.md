# Guía de Ejecución Rápida (Windows)

## 1. Ejecución directa con `ejecutar.bat` (Recomendada)
1. Asegúrate de tener **Java 17+** y el servicio **MySQL80** iniciado (`Win + R` → `services.msc` → iniciar `MySQL80`).
2. Haz doble clic en **`ejecutar.bat`**.
3. Ingresa tu usuario de MySQL (`root` por defecto), tu contraseña (`root` por defecto, o escribe `VACIO` si no tiene clave) y responde **`s`** para cargar `sql\01_BD_SistemaDomicilios_Final.sql` (también puedes cargarlo desde MySQL Workbench con `Ctrl + Shift + Enter`).
4. El lanzador ejecuta `app\sistema-domicilios-1.0.0.jar` y abre automáticamente **http://localhost:8080**.

## 2. Ejecución desde código fuente (sin instalar Maven)
```powershell
.\mvnw.cmd spring-boot:run
```

## 3. Pruebas con Postman
Importa `postman\Sistema_Domicilios_Cali.postman_collection.json` en Postman o ejecuta con Postman CLI:
```powershell
postman collection run postman\Sistema_Domicilios_Cali.postman_collection.json
```
