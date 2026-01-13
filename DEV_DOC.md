# Developer Documentation

This guide explains how to set up, build, and manage the project infrastructure from scratch.

---

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Make** (for using the Makefile)
- **Git** (to clone the repository)

Check installations:
```bash
docker --version
docker compose version
make --version
```

---

## Environment Setup from Scratch

### 1. Clone the repository
```bash
git clone <repository-url>
cd <project-directory>
```

### 2. Configuration Files

The project uses the following key configuration files:

- **`docker-compose.yml`**: Defines all services (Nginx, WordPress, MariaDB, etc.)
- **`Makefile`**: Contains shortcuts for common operations
- **`.env`**: Stores sensitive credentials and environment variables

### 3. Secrets and Environment Variables

Create your `.env` file in the project root: 

```bash
cp .env.example .env
```

Edit the `.env` file with your credentials: 

```env
# Database Configuration
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_db_password

# WordPress Configuration
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_TITLE=My WordPress Site
WP_URL=smarquez.42.fr

# Domain
DOMAIN_NAME=smarquez.42.fr
```

**⚠️ IMPORTANT:** Never commit the `.env` file to version control. It's included in `.gitignore`.

### 4. SSL Certificates

If using TLS/SSL, generate certificates: 
```bash
mkdir -p secrets/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/certs/nginx.key \
  -out secrets/certs/nginx.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=smarquez.42.fr"
```

---

## Build and Launch the Project

### Using the Makefile (Recommended)

```bash
# Build and start all containers
make

# Or step by step: 
make build    # Build Docker images
make up       # Start containers in background
```

### Using Docker Compose Directly

```bash
# Build images
docker compose build

# Start containers
docker compose up -d

# View logs
docker compose logs -f
```

### Stopping the Project

```bash
# Using Makefile
make down     # Stop and remove containers
make stop     # Just stop containers

# Using Docker Compose
docker compose down
docker compose stop
```

---

## Managing Containers and Volumes

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Check specific container logs
docker logs <container-name>
docker logs -f nginx        # Follow logs in real-time
docker logs --tail 50 mariadb

# Execute commands inside a container
docker exec -it <container-name> bash
docker exec -it wordpress bash
docker exec -it mariadb mysql -u root -p

# Restart a specific container
docker restart <container-name>

# Stop/start individual containers
docker stop <container-name>
docker start <container-name>

# Remove containers
docker compose down
docker rm <container-name>
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect <volume-name>

# Remove unused volumes
docker volume prune

# Remove specific volume (container must be stopped)
docker volume rm <volume-name>

# Backup a volume
docker run --rm -v <volume-name>:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar. gz /data
```

### Rebuild Everything from Scratch

```bash
# Using Makefile
make fclean   # Stop, remove containers, volumes, and images
make re       # Clean and rebuild everything

# Using Docker Compose
docker compose down -v          # Remove containers and volumes
docker compose build --no-cache # Rebuild without cache
docker compose up -d
```

---

## Data Storage and Persistence

### Volume Structure

The project uses Docker volumes for data persistence:

| Volume Name | Purpose | Container | Path Inside Container |
|-------------|---------|-----------|----------------------|
| `wp_data` | WordPress files | wordpress | `/var/www/html` |
| `db_data` | MariaDB database | mariadb | `/var/lib/mysql` |
| `certs` | SSL certificates | nginx | `/etc/nginx/certs` |

### Where Data is Stored

Docker volumes are stored on the host machine at:
```bash
# Linux
/var/lib/docker/volumes/

# Mac
~/Library/Containers/com.docker.docker/Data/vms/0/

# Check exact location: 
docker volume inspect <volume-name> | grep Mountpoint
```

### Data Persistence

- **Data persists** even when containers are stopped or removed
- **Data is deleted** only when volumes are explicitly removed with: 
  - `docker volume rm <volume-name>`
  - `docker compose down -v`
  - `make fclean`

### Backup and Restore

```bash
# Backup database
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD \
  $MYSQL_DATABASE > backup.sql

# Restore database
docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD \
  $MYSQL_DATABASE < backup.sql

# Backup WordPress files
docker run --rm -v wp_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/wordpress-backup.tar.gz /data
```

---

## Network Configuration

The services communicate through a custom Docker network:

```bash
# Inspect network
docker network ls
docker network inspect <network-name>

# Check container connections
docker inspect <container-name> | grep -A 20 Networks
```

---

## Useful Development Commands

```bash
# Clean Docker system (careful!)
docker system prune -a --volumes  # Removes everything unused

# Monitor resource usage
docker stats

# View container processes
docker top <container-name>

# Copy files to/from container
docker cp <container-name>:/path/in/container /host/path
docker cp /host/path <container-name>:/path/in/container
```

---

## Troubleshooting

### Port conflicts
```bash
# Check what's using port 443/80
sudo lsof -i :443
sudo netstat -tulpn | grep : 443

# Change ports in docker-compose.yml if needed
```

### Permission issues
```bash
# Fix volume permissions
docker exec -it <container-name> chown -R www-data:www-data /var/www/html
```

### Clean rebuild
```bash
make fclean
make
```

---

## Project Structure

```
.
├── Makefile
├── docker-compose.yml
├── .env (not in git)
├── .env.example
├── srcs/
│   ├── requirements/
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   └── conf/
│   │   ├── wordpress/
│   │   │   ├── Dockerfile
│   │   │   └── conf/
│   │   └── mariadb/
│   │       ├── Dockerfile
│   │       └── conf/
└── secrets/
    └── certs/
```

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [WordPress Docker Hub](https://hub.docker.com/_/wordpress)
- [MariaDB Docker Hub](https://hub.docker.com/_/mariadb)