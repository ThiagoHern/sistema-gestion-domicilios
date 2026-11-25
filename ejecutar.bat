@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 65001 >nul

echo ============================================================================
echo  Sistema de Gestion de Operaciones de Domicilios - Cali (Spring Boot + MySQL)
echo ============================================================================
echo.

where java >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No se encontro Java en el sistema.
    echo Instala Java 17 o superior ^(JDK 17+^) e intentalo de nuevo.
    pause
    exit /b 1
)

if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=3306
if "%DB_NAME%"=="" set DB_NAME=Sistema_gestion_operaciones_domicilios

powershell -NoProfile -Command "$t = New-Object System.Net.Sockets.TcpClient; try { $t.Connect('%DB_HOST%', %DB_PORT%); $t.Close(); exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo [AVISO] No se detecta MySQL escuchando en %DB_HOST%:%DB_PORT%.
    echo         Abre "Servicios" de Windows e inicia "MySQL80" ^(o ejecuta "net start MySQL80" como Administrador^).
    echo.
)

set /p INPUT_USER=Usuario de MySQL [root]: 
if "!INPUT_USER!"=="" (set "DB_USER=root") else (set "DB_USER=!INPUT_USER!")

set /p INPUT_PASS=Contrasena de MySQL ^(Enter=root, escribe VACIO si no tiene clave^): 
if "!INPUT_PASS!"=="" (
    set "DB_PASS=root"
) else if /i "!INPUT_PASS!"=="VACIO" (
    set "DB_PASS="
) else (
    set "DB_PASS=!INPUT_PASS!"
)

set "MYSQL_EXE="
where mysql >nul 2>&1
if %ERRORLEVEL%==0 (
    set "MYSQL_EXE=mysql"
) else if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
)

if not "!MYSQL_EXE!"=="" (
    set /p LOAD_SQL=Deseas cargar/reiniciar sql\01_BD_SistemaDomicilios_Final.sql en MySQL? ^(S/N^) [N]: 
    if /i "!LOAD_SQL!"=="S" (
        echo Cargando base de datos en MySQL...
        if "!DB_PASS!"=="" (
            "!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u "!DB_USER!" --default-character-set=utf8mb4 < "sql\01_BD_SistemaDomicilios_Final.sql"
        ) else (
            "!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u "!DB_USER!" -p"!DB_PASS!" --default-character-set=utf8mb4 < "sql\01_BD_SistemaDomicilios_Final.sql"
        )
        if errorlevel 1 (
            echo [AVISO] No se pudo cargar automaticamente el SQL. Verifica que MySQL80 este iniciado y la clave sea correcta.
        ) else (
            echo [OK] Base de datos cargada correctamente.
        )
    )
) else (
    echo [INFO] Cliente mysql.exe no detectado en PATH. Asegurate de haber ejecutado sql\01_BD_SistemaDomicilios_Final.sql en MySQL Workbench.
)

echo.
echo Iniciando servidor Spring Boot en http://localhost:8080 ...
echo Se abrira el navegador automaticamente cuando el servidor este listo.
echo ^(Para detener el servidor, cierra esta ventana o presiona Ctrl + C^)
echo.

start "" /b powershell -NoProfile -Command "for ($i=0; $i -lt 30; $i++) { Start-Sleep -Seconds 1; try { $r = Invoke-WebRequest -Uri 'http://localhost:8080/' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { Start-Process 'http://localhost:8080'; break } } catch {} }"

if exist "app\sistema-domicilios-1.0.0.jar" (
    java -jar "app\sistema-domicilios-1.0.0.jar" --server.port=8080 --spring.datasource.url="jdbc:mysql://%DB_HOST%:%DB_PORT%/%DB_NAME%?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true&useSSL=false" --spring.datasource.username="!DB_USER!" --spring.datasource.password="!DB_PASS!"
) else (
    call .\mvnw.cmd spring-boot:run
)

if errorlevel 1 (
    echo.
    echo [ERROR] El servidor finalizo con errores. Verifica que MySQL 8 este encendido y que las credenciales sean correctas.
)
pause
endlocal
