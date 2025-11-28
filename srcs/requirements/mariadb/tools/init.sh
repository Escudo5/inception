#!/bin/bash


# Script para configurar MariaDB la primera vez.
# Si ya esta configurado inicia el servidor

if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "Initializing MariaDB..."

    # Crear las tablas del sistema de MariaDB
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Iniciar MariaDB en modo temporal (sin red, solo socket local)
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql_init.sock &
    MYSQL_PID=$!

    # Esperar a que MariaDB esté lista para recibir comandos
    for i in {1..30}; do
        if mysql --socket=/tmp/mysql_init.sock -e "SELECT 1" &>/dev/null; then
            break
        fi
        echo "Waiting for MySQL to start..."
        sleep 1
    done

# Configuracion inicial y crear DB.
    mysql --socket=/tmp/mysql_init.sock -u root << EOF


-- Luego cambiar contraseña
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';

-- Eliminar usuarios anónimos (seguridad)
DELETE FROM mysql.user WHERE User='';

-- Eliminar accesos remotos de root (seguridad)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Eliminar base de datos de prueba
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Crear base de datos para WordPress
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;

-- Crear usuario para WordPress con acceso desde cualquier host
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';

-- Dar todos los permisos sobre la BD de WordPress
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';

FLUSH PRIVILEGES;
EOF

    kill $MYSQL_PID
    wait $MYSQL_PID

    echo "MariaDB initialized"
else
    echo "MariaDB arleady initilized"
fi

exec mysql --user=mysql