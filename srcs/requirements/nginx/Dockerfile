FROM debian:bookworm

# instalar NGINX y OpenSSL para certificados
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

#crear carpetas para certificados
RUN mkdir -p /etc/nginx/ssl

# Generar certificado SSL autofirmado
# -x509: certificado autofirmado
# -nodes: sin encriptación de clave privada
# -days 365: válido por 1 año
# -newkey rsa:2048: clave RSA de 2048 bits
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42Madrid/CN=smarquez.42.fr"

# copiar archivos de config personalizados

COPY conf/enginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/sites-enabled/default

RUN mkdir -p var/www/html && \
    chown -R www-data:www-data /var/www/thml && \
    chmod -R 755 /var/www/html

EXPOSE 443

# iniciar en primer plano, daemon off
CMD ["nginx", "-g", "daemon off;"]