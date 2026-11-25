#!/usr/bin/env bash
set -e

echo "============================================================================"
echo " Sistema de Gestión de Operaciones de Domicilios - Cali (Spring Boot + MySQL)"
echo "============================================================================"

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-3306}"
export DB_NAME="${DB_NAME:-Sistema_gestion_operaciones_domicilios}"

read -rp "Usuario de MySQL [root]: " INPUT_USER
export DB_USER="${INPUT_USER:-root}"

read -rsp "Contraseña de MySQL [root]: " INPUT_PASS
echo ""
export DB_PASS="${INPUT_PASS:-root}"

if command -v mysql >/dev/null 2>&1; then
  read -rp "¿Deseas cargar/reiniciar sql/01_BD_SistemaDomicilios_Final.sql en MySQL? (s/N): " LOAD_SQL
  if [[ "$LOAD_SQL" =~ ^[sS]$ ]]; then
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --default-character-set=utf8mb4 < sql/01_BD_SistemaDomicilios_Final.sql
    echo "[OK] Base de datos cargada correctamente."
  fi
fi

chmod +x mvnw
echo "Iniciando servidor Spring Boot en http://localhost:8080 ..."
./mvnw spring-boot:run
