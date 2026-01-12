#!/bin/bash
set -euo pipefail

# Init script robusto para MariaDB
# - Crea/asegura /run/mysqld y /var/lib/mysql
# - Inicializa el datadir si hace falta
# - Arranca un mysqld temporal por socket para ejecutar la SQL de inicialización
# - Para el servidor temporal y arranca mysqld en primer plano (exec)


DATADIR="${DATADIR:-/var/lib/mysql}"
RUNDIR="${RUNDIR:-/run/mysqld}"
# Usuario de sistema con el que corre mysqld (no confundir con el usuario de aplicación/WP)
MYSQL_SYSTEM_USER="${MYSQL_SYSTEM_USER:-mysql}"
MYSQL_USER="${MYSQL_USER:-mysql}"
# Variables esperadas en el entorno: MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER (nombre para WP), MYSQL_PASSWORD

# Asegurar directorios y permisos
mkdir -p "$RUNDIR"
chown -R "$MYSQL_SYSTEM_USER:$MYSQL_SYSTEM_USER" "$RUNDIR"
chmod 755 "$RUNDIR"

mkdir -p "$DATADIR"
chown -R "$MYSQL_SYSTEM_USER:$MYSQL_SYSTEM_USER" "$DATADIR"
chmod 700 "$DATADIR"

# Función para matar servidor temporal en caso de salida prematura
_tmp_pid_cleanup() {
  if [ -n "${MYSQLD_TMP_PID:-}" ]; then
    kill "${MYSQLD_TMP_PID}" 2>/dev/null || true
    wait "${MYSQLD_TMP_PID}" 2>/dev/null || true
  fi
}
trap _tmp_pid_cleanup EXIT

# Detectar si ya está inicializado (miramos la base 'mysql')
echo "DEBUG: Checking if DATADIR='$DATADIR' exists..."
ls -la "$DATADIR" 2>&1 | head -10
echo "DEBUG: Checking if $DATADIR/mysql exists..."
[ -d "$DATADIR/mysql" ] && echo "  DIR EXISTS" || echo "  DIR MISSING"
echo "DEBUG: Checking if $DATADIR is empty..."
if [ -z "$(ls -A "$DATADIR" 2>/dev/null)" ]; then
  echo "  DATADIR IS EMPTY"
else
  echo "  DATADIR IS NOT EMPTY"
fi

if [ ! -d "$DATADIR/mysql" ] || [ -z "$(ls -A "$DATADIR" 2>/dev/null)" ]; then
  echo "Initializing MariaDB data directory..."

  # Inicializar de forma adecuada según disponibilidad de opciones
  if mysqld --help 2>/dev/null | grep -qi 'initialize'; then
    echo "Using mysqld --initialize-insecure"
    mysqld --initialize-insecure --user="$MYSQL_SYSTEM_USER" --datadir="$DATADIR"
  else
    echo "Using mysql_install_db fallback"
    mysql_install_db --user="$MYSQL_SYSTEM_USER" --datadir="$DATADIR" || true
  fi

  # Iniciar servidor temporal (solo socket) para crear usuarios y DB
  SOCKET_INIT="$RUNDIR/mysql_init.sock"
  echo "Starting temporary mysqld (socket=$SOCKET_INIT)..."
  mysqld --user="$MYSQL_SYSTEM_USER" --skip-networking --socket="$SOCKET_INIT" --datadir="$DATADIR" &
  MYSQLD_TMP_PID=$!

  # Esperar hasta 60s a que acepte conexiones por socket
  i=0
  until mysql --socket="$SOCKET_INIT" -e "SELECT 1" >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge 60 ]; then
      echo "ERROR: temporary mysqld did not start within 60s" >&2
      _tmp_pid_cleanup
      exit 1
    fi
    echo "Waiting for temporary mysqld to be ready... ($i)"
    sleep 1
  done

  echo "Running initial SQL..."
  mysql --socket="$SOCKET_INIT" <<SQL
-- Cambiar contraseña root si se pasó MYSQL_ROOT_PASSWORD
$( [ -n "${MYSQL_ROOT_PASSWORD:-}" ] && echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" )

DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\_%';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE:-wordpress}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER:-wp_user}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:-password}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-wordpress}\`.* TO '${MYSQL_USER:-wp_user}'@'%';

-- Test connection from WordPress
SELECT User, Host FROM mysql.user WHERE User='${MYSQL_USER:-wp_user}';
SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${MYSQL_DATABASE:-wordpress}';

FLUSH PRIVILEGES;
SQL

  echo "Stopping temporary mysqld..."
  kill "$MYSQLD_TMP_PID"
  wait "$MYSQLD_TMP_PID" 2>/dev/null || true

  unset MYSQLD_TMP_PID
  trap - EXIT

  echo "MariaDB initialized"
else
  echo "MariaDB already initialized - Resetting credentials with skip-grant-tables..."

  # Reiniciar con skip-grant-tables para actualizar credenciales incluso si no coinciden
  SOCKET_INIT="$RUNDIR/mysql_init.sock"
  echo "Starting temporary mysqld with skip-grant-tables (socket=$SOCKET_INIT)..."
  mysqld --user="$MYSQL_SYSTEM_USER" --skip-networking --skip-grant-tables --socket="$SOCKET_INIT" --datadir="$DATADIR" &
  MYSQLD_TMP_PID=$!

  i=0
  until mysql --protocol=socket --socket="$SOCKET_INIT" -e "SELECT 1" >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge 30 ]; then
      echo "ERROR: temporary mysqld (skip-grant-tables) did not start within 30s" >&2
      _tmp_pid_cleanup
      exit 1
    fi
    echo "Waiting for temporary mysqld to be ready... ($i)"
    sleep 1
  done

  echo "Running credential reset SQL..."
  mysql --protocol=socket --socket="$SOCKET_INIT" <<SQL
FLUSH PRIVILEGES;

-- Resetear credenciales de root (solo si existen)
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD:-change_this_root_password}';

-- Eliminar usuario antiguo de wp_user
DROP USER IF EXISTS '${MYSQL_USER:-wp_user}'@'%';
DROP USER IF EXISTS '${MYSQL_USER:-wp_user}'@'localhost';

-- Crear usuario nuevo con credenciales correctas desde cualquier host
CREATE USER '${MYSQL_USER:-wp_user}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:-change_this_wp_password}';

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE:-wordpress}\`;

-- Dar todos los permisos
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-wordpress}\`.* TO '${MYSQL_USER:-wp_user}'@'%';

-- Flush para aplicar cambios
FLUSH PRIVILEGES;

-- Verificación
SELECT '=== USUARIOS CREADOS ===' as info;
SELECT User, Host FROM mysql.user WHERE User IN ('root', '${MYSQL_USER:-wp_user}');
SELECT '=== BASE DE DATOS ===' as info;
SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${MYSQL_DATABASE:-wordpress}';
SQL

  echo "Stopping temporary mysqld..."
  kill "$MYSQLD_TMP_PID"
  wait "$MYSQLD_TMP_PID" 2>/dev/null || true

  unset MYSQLD_TMP_PID
  trap - EXIT

  echo "Credentials reset complete"
fi

# Asegurar permisos finales
chown -R "$MYSQL_SYSTEM_USER:$MYSQL_SYSTEM_USER" "$DATADIR"
mkdir -p "$RUNDIR"
chown -R "$MYSQL_SYSTEM_USER:$MYSQL_SYSTEM_USER" "$RUNDIR"
chmod 755 "$RUNDIR"

# Ejecutar el servidor en primer plano (PID 1)
echo "Executing mysqld (foreground)..."
exec mysqld --user="$MYSQL_SYSTEM_USER" --console