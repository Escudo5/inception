# Imagen de debian bookworm
FROM debian:bookworm


# INstalar MariaDB Server y limpiar caché de apt.
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*


# COnfiguracion del servidor
# IMPORTANTE: Copiar como .cnf para que MariaDB lo incluya
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copiar script de inicializacion  y hacerlo ejecutable
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Crear carpetas
# - /var/run/mysqld: socket de MariaDB
# - /var/log/mysql: logs del servidor
# - /var/lib/mysql: datos de la base de datos

RUN mkdir -p /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql && \
    chmod 755 /var/log/mysql && \
    chmod 777 /var/run/mysqld && \
    touch /var/log/mysql/error.log && \
    chown mysql:mysql /var/log/mysql/error.log && \
    chmod 644 /var/log/mysql/error.log


# Expoenr puerto 3306 (puerto de MySQL y MariaDB)
EXPOSE 3306

# Ejecutar script de setup
CMD ["/usr/local/bin/init.sh"]