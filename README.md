*This project has been created as part of the 42 curriculum by smarquez.*

## Description

Inception is a system administration project that introduces containerization concepts through Docker. The goal is to set up a complete infrastructure composed of multiple services running in separate Docker containers, all orchestrated using Docker Compose.

This project implements a WordPress hosting environment with NGINX as a reverse proxy, MariaDB as the database server, and PHP-FPM handling WordPress application logic. Each service runs in its own container, communicates through a dedicated Docker network, and stores persistent data using volumes.

The main objectives are to:
- Understand virtualization and containerization principles
- Learn Docker architecture and best practices
- Build custom Dockerfile configurations for each service
- Manage multi-container applications with Docker Compose
- Implement security practices including TLS encryption, environment variables, and secrets management

## Instructions

### Prerequisites

- A Virtual Machine (as required by the project specifications)
- Docker and Docker Compose installed
- A text editor or IDE for configuration
- Basic knowledge of networking and system administration concepts

### Initial Setup

1. **Configure your domain name:**
   Add the following line to `/etc/hosts`:
   ```bash
   sudo echo "127.0.0.1 sergio.42.fr" >> /etc/hosts
   ```
   Replace `smarquez` with your actual 42 login.

2. **Set up environment variables:**
   Create the `.env` file in `srcs/` directory:
   ```bash
   cd srcs
   cat > .env << 'ENVEOF'
   DOMAIN_NAME=smarquez.42.fr
   MYSQL_USER=wordpress_user
   MYSQL_PASSWORD=your_password_here
   MYSQL_ROOT_PASSWORD=your_root_password_here
   WORDPRESS_ADMIN_USER=admin_user
   WORDPRESS_ADMIN_PASSWORD=admin_password_here
   WORDPRESS_ADMIN_EMAIL=admin@example.com
   ENVEOF
   ```

3. **Set up Docker secrets:**
   Create a `secrets/` directory at the root level with your credentials:
   ```bash
   mkdir -p secrets
   echo "your_secure_password" > secrets/db_password.txt
   echo "your_secure_root_password" > secrets/db_root_password.txt
   echo "admin_credentials" > secrets/credentials.txt
   ```

4. **Build and launch the infrastructure:**
   ```bash
   make
   ```

### Available Make Commands

- `make` or `make up` — Build and start all services
- `make down` — Stop all running containers
- `make clean` — Stop containers and remove volumes
- `make fclean` — Complete cleanup (removes images, volumes, and containers)
- `make re` — Rebuild everything from scratch
- `make logs` — Display container logs in real-time

### Accessing the Application

Once the infrastructure is running:

- **Website:** Open your browser and navigate to `https://smarquez.42.fr` (replace with your login)
- **WordPress Admin:** Use your configured credentials to log in
- **Database:** MariaDB is not directly accessible from outside the network; access it through WordPress

**Note:** You may see SSL certificate warnings since this uses a self-signed certificate. This is expected in a local development environment.

## Project Structure

```
inception/
├── Makefile                    # Orchestration and build commands
├── README.md                   # This file
├── secrets/                    # Sensitive credentials (git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                    # Environment variables (git-ignored)
    ├── docker-compose.yml      # Container orchestration configuration
    └── requirements/           # Service definitions
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/           # Database configuration files
        │   └── tools/          # Initialization scripts
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/           # NGINX configuration
        │   └── tools/          # Setup scripts
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── tools/          # Installation and setup scripts
            └── [wordpress files mounted as volume]
```

## Key Design Choices

### Docker vs Virtual Machines
Virtual machines create complete operating system instances with full isolation but consume significant resources. Docker containers are lightweight, sharing the host kernel while maintaining isolation at the application level. For this project, containers are more efficient for running individual services.

### Secrets vs Environment Variables
Environment variables are visible in process listings and logs, making them unsuitable for sensitive data. Docker Secrets provide encrypted storage and are only accessible to containers that explicitly need them. This project uses secrets for database passwords and credentials.

### Docker Network vs Host Network
The `host` network mode shares the host's network interface, which simplifies networking but loses container isolation. A custom Docker network (`inception`) provides proper isolation, allowing containers to communicate by service name while remaining protected from the host network.

### Docker Volumes vs Bind Mounts
Bind mounts map host directories directly into containers, making them easier to access but less portable. Named volumes are managed by Docker, offering better performance, portability, and integration with the Docker ecosystem. This project uses volumes for persistent data.

## How AI Was Used

AI assistance was utilized for:
- **Dockerfile optimization:** Understanding base images, layer caching, and best practices for minimal image sizes
- **PHP-FPM configuration:** Understanding process management and socket communication
- **Docker Compose syntax:** Verifying proper network and volume declarations
- **Documentation:** Structuring clear, comprehensive documentation

All code has been reviewed, tested, and modified to match project requirements and security standards.

## Resources

### Docker and Containerization
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Understanding Docker Networking](https://docs.docker.com/network/)

### NGINX
- [NGINX Official Documentation](https://nginx.org/en/docs/)
- [NGINX TLS Configuration](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)

### MariaDB
- [MariaDB Server Documentation](https://mariadb.com/kb/en/mariadb-server/)
- [MariaDB Docker Image Guide](https://hub.docker.com/_/mariadb)

### WordPress
- [WordPress Official Documentation](https://wordpress.org/support/)
- [WordPress Security Hardening](https://wordpress.org/support/article/hardening-wordpress/)

### System Administration
- [Linux System Administration Basics](https://www.linux.org/threads/linux-administration.11/)
- [Process Management and Daemons](https://en.wikipedia.org/wiki/Daemon_(computing))
- [PID 1 in Containers](https://docs.docker.com/config/containers/multi-service_container/)

## Troubleshooting

### Services won't start
- Check environment variables in `srcs/.env`
- Verify secrets files exist and have correct permissions
- Review container logs: `docker logs <container_name>`

### Domain name not resolving
- Ensure `/etc/hosts` has the correct entry
- Clear your browser cache or use incognito mode
- Try accessing via IP address directly

### SSL certificate errors
- This is normal with self-signed certificates
- Add an exception in your browser or use curl with `-k` flag

### Volume permission issues
- Ensure `/home/smarquez/data/` directory exists
- Check directory ownership and permissions
- Recreate volumes if necessary with `make fclean` then `make`
