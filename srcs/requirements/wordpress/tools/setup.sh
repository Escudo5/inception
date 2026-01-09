#!/bin/bash

MAX_WAIT=180
WAITED=0

# Debug: mostrar las credenciales que vamos a usar
echo "Intentando conectar con:"
echo "  Host: mariadb"
echo "  Usuario: $MYSQL_USER"
echo "  Base de datos: $MYSQL_DATABASE"
echo "  Contraseña: (oculta, primeros 3 caracteres: ${MYSQL_PASSWORD:0:3}***)"
echo ""

# Esperar a que MariaDB esté lista y acepte conexiones
until MYSQL_PWD="$MYSQL_PASSWORD" timeout 5 mysql -h mariadb -u"$MYSQL_USER" -e "SELECT 1" >/dev/null 2>&1; do
if [ $WAITED -ge $MAX_WAIT ]; then
	echo "ERROR: MariaDB not ready after $MAX_WAIT seconds" >&2
	echo "Intenté conectar con: mysql -h mariadb -u $MYSQL_USER -p***" >&2
	echo "Si la contraseña es incorrecta, MariaDB rechazará la conexión." >&2
	exit 1
fi
echo "Waiting for MariaDB... ($WAITED/$MAX_WAIT seconds)"
sleep 3
WAITED=$((WAITED + 3))
done

echo "MariaDB is ready"

# Verificar si WordPress ya está instalado (comprobando wp-config.php)
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Installing WordPress..."

    # Descargar archivos core de WordPress
	wp core download --allow-root

    # Crear wp-config.php con conexion a DB
    wp config create \
    	--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$MYSQL_PASSWORD \
		--dbhost=mariadb:3306 \
		--allow-root

    # Instalar WordPress (crear tablas y configuración inicial)
	wp core install \
		--url=$DOMAIN_NAME \
		--title="$WP_TITLE" \
		--admin_user=$WP_ADMIN_USER \
		--admin_password=$WP_ADMIN_PASSWORD \
		--admin_email=$WP_ADMIN_EMAIL \
		--allow-root

    # Crear usuario adicional con rol de autor
	wp user create \
		$WP_USER \
		$WP_USER_EMAIL \
		--role=author \
		--user_pass=$WP_USER_PASSWORD \
		--allow-root 2>/dev/null || echo "User $WP_USER already exists"

    echo "Wordpress installed"
else
    echo "Wordpress already installed"
fi

# Establecer permisos correctos para el servidor web
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Iniciar PHP-FPM en primer plano (daemon off)
exec php-fpm8.2 -F