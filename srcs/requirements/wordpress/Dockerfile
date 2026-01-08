FROM debian:bookworm

# instalar PHP y extensiones

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-soap \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-zip \
    curl \
    default-mysql-client\
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# instalar herramienta de gestion de wordpress (gestiona WP desde la terminal)

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# configurar php para escuchar en wordpress 9000
RUN mkdir -p /run/php && \
    sed -i 's|listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Establecer directorio de trabajo
WORKDIR /var/www/html

# copiar scripts de inicializacion y hacerlos ejecutables
COPY tools/make_dir.sh /usr/local/bin/make_dir.sh
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/make_dir.sh /usr/local/bin/setup.sh

EXPOSE 9000

# Ejecutar scripts de setup al iniciar contenedor
CMD ["/bin/bash", "-c", "/usr/local/bin/make_dir.sh && /usr/local/bin/setup.sh"]