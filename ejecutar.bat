@echo off
setlocal
chcp 65001 >nul
echo ============================================================================
echo  Sistema de Gestion de Operaciones de Domicilios - Cali (Spring Boot + MySQL)
echo ============================================================================
echo.

if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=3306
if "%DB_NAME%"=="" set DB_NAME=Sistema_gestion_operaciones_domicilios

set /p INPUT_USER=Usuario de MySQL [root]: 
if "%INPUT_USER%"=="" (set DB_USER=root) else (set DB_USER=%INPUT_USER%)

set /p INPUT_PASS=Contrasena de MySQL [root]: 
if "%INPUT_PASS%"=="" (set DB_PASS=root) else (set DB_PASS=%INPUT_PASS%)

set MYSQL_EXE=
where mysql >nul 2>&1
if %ERRORLEVEL%==0 (
    set MYSQL_EXE=mysql
) else if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
)

if not "%MYSQL_EXE%"=="" (
    set /p LOAD_SQL=Deseas cargar/reiniciar sql\01_BD_SistemaDomicilios_Final.sql en MySQL? (S/N) [N]: 
    if /i "%LOAD_SQL%"=="S" (
        echo Cargando base de datos en MySQL...
        "%MYSQL_EXE%" -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% --default-character-set=utf8mb4 < sql\01_BD_SistemaDomicilios_Final.sql
        if errorlevel 1 (
            echo [AVISO] No se pudo cargar automaticamente el SQL. Puedes ejecutarlo desde MySQL Workbench.
        ) else (
            echo [OK] Base de datos cargada correctamente.
        )
    )
) else (
    echo [INFO] Cliente mysql.exe no detectado en PATH. Asegurate de haber ejecutado sql\01_BD_SistemaDomicilios_Final.sql en MySQL Workbench.
)

echo.
echo Iniciando servidor Spring Boot en http://localhost:8080 ...
echo (La primera vez puede tardar unos segundos descargando dependencias Maven)
start "" http://localhost:8080
call .\mvnw.cmd spring-boot:run
endlocal
