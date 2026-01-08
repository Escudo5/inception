#!/bin/bash

# Crear directorios necesarios para WordPress
mkdir -p /var/www/html
mkdir -p /run/php

# Asegurar permisos correctos
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
