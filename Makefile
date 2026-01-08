
# Colores para output
GREEN = \033[0;32m
RED = \033[0;31m
RESET = \033[0m

# Directorios
SRCS_DIR = srcs
DATA_DIR = /home/$(USER)/data

# Docker compose file
COMPOSE_FILE = $(SRCS_DIR)/docker-compose.yml

.PHONY: all up down build clean fclean re logs ps

all: up

# Crear directorios de datos si no existen
$(DATA_DIR):
	@echo "$(GREEN)Creating data directories...$(RESET)"
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mysql_log

# Levantar servicios
up: $(DATA_DIR)
	@echo "$(GREEN)Starting services...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d

# Construir y levantar
build: $(DATA_DIR)
	@echo "$(GREEN)Building and starting services...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d --build

# Parar servicios
down:
	@echo "$(RED)Stopping services...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down

# Parar y limpiar volúmenes
clean: down
	@echo "$(RED)Removing volumes...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down -v

# Limpieza completa (contenedores, volúmenes, imágenes, datos del host)
fclean: clean
	@echo "$(RED)Removing all data and images...$(RESET)"
	@docker rmi -f mariadb:inception wordpress:inception nginx:inception 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)/mariadb/* $(DATA_DIR)/wordpress/* $(DATA_DIR)/mysql_log/* 2>/dev/null || true
	@echo "$(GREEN)Clean complete!$(RESET)"

# Reconstruir desde cero
re: fclean build

# Ver logs
logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

# Ver estado de contenedores
ps:
	@docker compose -f $(COMPOSE_FILE) ps
