#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "============================================================================"
echo " Sistema de Gestión de Operaciones de Domicilios - Cali (Spring Boot + MySQL)"
echo "============================================================================"

if ! command -v java >/dev/null 2>&1; then
  echo "[ERROR] No se encontró Java. Instala Java 17 o superior e inténtalo de nuevo."
  exit 1
fi

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-3306}"
export DB_NAME="${DB_NAME:-Sistema_gestion_operaciones_domicilios}"

read -rp "Usuario de MySQL [root]: " INPUT_USER
export DB_USER="${INPUT_USER:-root}"

read -rsp "Contraseña de MySQL (Enter=root, escribe VACIO si no tiene clave): " INPUT_PASS
echo ""
if [[ -z "$INPUT_PASS" ]]; then
  export DB_PASS="root"
elif [[ "$INPUT_PASS" == "VACIO" || "$INPUT_PASS" == "vacio" ]]; then
  export DB_PASS=""
else
  export DB_PASS="$INPUT_PASS"
fi

if command -v mysql >/dev/null 2>&1; then
  read -rp "¿Deseas cargar/reiniciar sql/01_BD_SistemaDomicilios_Final.sql en MySQL? (s/N): " LOAD_SQL
  if [[ "$LOAD_SQL" =~ ^[sS]$ ]]; then
    if [[ -z "$DB_PASS" ]]; then
      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --default-character-set=utf8mb4 < sql/01_BD_SistemaDomicilios_Final.sql
    else
      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --default-character-set=utf8mb4 < sql/01_BD_SistemaDomicilios_Final.sql
    fi
    echo "[OK] Base de datos cargada correctamente."
  fi
fi

echo "Iniciando servidor Spring Boot en http://localhost:8080 ..."
if [[ -f "app/sistema-domicilios-1.0.0.jar" ]]; then
  exec java -jar app/sistema-domicilios-1.0.0.jar \
    --server.port=8080 \
    --spring.datasource.url="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true&useSSL=false" \
    --spring.datasource.username="${DB_USER}" \
    --spring.datasource.password="${DB_PASS}"
else
  chmod +x mvnw
  exec ./mvnw spring-boot:run
fi
