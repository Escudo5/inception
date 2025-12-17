#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
MYSQL_USER="mysql"

# Asegurar runtime dir (donde se crea el socket)
mkdir -p "$RUNDIR"
chown -R "$MYSQL_USER":"$MYSQL_USER" "$RUNDIR"
chmod 755 "$RUNDIR"

# Comprobar si ya está inicializado (miramos la base 'mysql')
if [ ! -d "$DATADIR/mysql" ] || [ -z "$(ls -A "$DATADIR" 2>/dev/null)" ]; then
  echo "Initializing MariaDB data directory..."

  # Inicializar de forma segura
  if mysqld --help 2>/dev/null | grep -q initialize; then
    mysqld --initialize-insecure --user="$MYSQL_USER" --datadir="$DATADIR"
  else
    mysql_install_db --user="$MYSQL_USER" --datadir="$DATADIR" || true
  fi

  echo "Starting temporary mysqld for initial configuration..."
  mysqld --user="$MYSQL_USER" --skip-networking --socket="$RUNDIR/mysql_init.sock" --datadir="$DATADIR" &
  MYSQLD_TMP_PID=$!

  # Esperar a que acepte conexiones por socket
  i=0
  until mysql --socket="$RUNDIR/mysql_init.sock" -e "SELECT 1" >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge 60 ]; then
      echo "ERROR: temporary mysqld did not start within 60s" >&2
      kill "$MYSQLD_TMP_PID" 2>/dev/null || true
      exit 1
    fi
    echo "Waiting for temporary mysqld to be ready... ($i)"
    sleep 1
  done

  echo "Running initial SQL..."
  mysql --socket="$RUNDIR/mysql_init.sock" <<-SQL
    $( [ -n "$MYSQL_ROOT_PASSWORD" ] && echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" )
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\_%';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE:-wordpress}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER:-wp_user}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:-password}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-wordpress}\`.* TO '${MYSQL_USER:-wp_user}'@'%';
    FLUSH PRIVILEGES;
  SQL

  echo "Stopping temporary mysqld..."
  kill "$MYSQLD_TMP_PID"
  wait "$MYSQLD_TMP_PID" 2>/dev/null || true

  echo "MariaDB initialized"
else
  echo "MariaDB already initialized"
fi

# Asegurar permisos de datos
chown -R "$MYSQL_USER":"$MYSQL_USER" "$DATADIR"

# Asegurar runtime dir y permisos otra vez por si acaso
mkdir -p "$RUNDIR"
chown -R "$MYSQL_USER":"$MYSQL_USER" "$RUNDIR"
chmod 755 "$RUNDIR"

# Ejecutar el servidor en primer plano (PID 1)
echo "Executing mysqld (foreground)..."
exec mysqld --user="$MYSQL_USER" --console