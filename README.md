# Inception Project

Este proyecto implementa una infraestructura Docker multi-contenedor con:
- NGINX (TLSv1.2/TLSv1.3)
- WordPress + PHP-FPM
- MariaDB

## Configuración Inicial

1. Copia el archivo de configuración de ejemplo:
```bash
cp srcs/.env.example srcs/.env
```

2. Edita `srcs/.env` con tus valores reales:
   - Cambia todas las contraseñas
   - Ajusta `DOMAIN_NAME` con tu login de 42: `https://login.42.fr`

3. Añade tu dominio al archivo `/etc/hosts`:
```bash
sudo echo "127.0.0.1 login.42.fr" >> /etc/hosts
```

4. Ejecuta el proyecto:
```bash
make
```

## Comandos Disponibles

- `make` / `make up` - Inicia los servicios
- `make build` - Construye y levanta los servicios
- `make down` - Para los servicios
- `make clean` - Para y elimina volúmenes
- `make fclean` - Limpieza completa (imágenes, volúmenes, datos)
- `make re` - Reconstruye desde cero
- `make logs` - Ver logs en tiempo real
- `make ps` - Ver estado de contenedores

## Estructura

```
inception/
├── Makefile
└── srcs/
    ├── .env.example        # Plantilla de configuración
    ├── docker-compose.yml  # Orquestación de servicios
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

## Acceso

- URL: `https://login.42.fr` (reemplaza 'login' con tu usuario)
- Admin: Usuario y contraseña configurados en `.env`
