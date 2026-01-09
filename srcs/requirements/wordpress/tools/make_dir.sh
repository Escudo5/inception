#!/bin/bash

# Crear directorios necesarios para WordPress
mkdir -p /var/www/html
mkdir -p /run/php

# Asegurar permisos correctos (nginx user www-data necesita poder leer)
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Asegurar que el directorio raíz sea accesible
chmod 755 /var/www
