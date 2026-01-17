# =============================================================================
# Variables
# =============================================================================
COMPOSE_FILE := srcs/docker-compose.yml
ENV_FILE := srcs/.env

# Docker Compose command
DC := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# =============================================================================
# Main Targets
# =============================================================================
all: env-check up

up: env-check setup-dirs ## Start all containers
	@echo "$(GREEN)Starting containers...$(NC)"
	$(DC) up -d --build
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  WordPress is running!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@. ./$(ENV_FILE) && echo "  Access: $(YELLOW)https://$${DOMAIN_NAME:-localhost}$(NC)"
	@echo "$(GREEN)========================================$(NC)"

down: ## Stop all containers (keep volumes)
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(DC) down

stop: ## Stop containers without removing
	$(DC) stop

start: ## Start stopped containers
	$(DC) start
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  WordPress is running!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@. ./$(ENV_FILE) && echo "  Access: $(YELLOW)https://$${DOMAIN_NAME:-localhost}$(NC)"
	@echo "$(GREEN)========================================$(NC)"

restart: down up ## Restart all containers

build: env-check ## Build images without starting
	@echo "$(GREEN)Building images...$(NC)"
	$(DC) build

build-no-cache: env-check ## Build images without cache
	@echo "$(GREEN)Building images (no cache)...$(NC)"
	$(DC) build --no-cache

# =============================================================================
# Cleanup Targets
# =============================================================================
clean: ## Stop and remove containers, networks, volumes
	@echo "$(YELLOW)Cleaning up containers and volumes...$(NC)"
	$(DC) down -v --remove-orphans

fclean: clean ## Full cleanup including images and data
	@echo "$(RED)Removing all project images...$(NC)"
	$(DC) down --rmi all
	docker system prune -f
	@echo "$(RED)Removing data directory...$(NC)"
	rm -rf srcs/data

re: fclean all ## Full rebuild

# =============================================================================
# Status & Logs
# =============================================================================
ps: ## Show running containers
	$(DC) ps

logs: ## Follow all container logs
	$(DC) logs -f

logs-wp: ## Follow WordPress logs
	$(DC) logs -f wordpress

logs-db: ## Follow MariaDB logs
	$(DC) logs -f mariadb

logs-nginx: ## Follow Nginx logs
	$(DC) logs -f nginx

# =============================================================================
# Shell Access
# =============================================================================
shell-wp: ## Open shell in WordPress container
	$(DC) exec wordpress bash

shell-db: ## Open shell in MariaDB container
	$(DC) exec mariadb bash

shell-nginx: ## Open shell in Nginx container
	$(DC) exec nginx bash

# =============================================================================
# Database Operations
# =============================================================================
db-cli: ## Connect to MariaDB CLI
	$(DC) exec mariadb mysql -u $${DB_USER} -p$${DB_PASSWORD} $${DB_NAME}

db-dump: ## Dump database to backup.sql
	@echo "$(GREEN)Dumping database...$(NC)"
	$(DC) exec mariadb mysqldump -u $${DB_USER} -p$${DB_PASSWORD} $${DB_NAME} > backup.sql
	@echo "$(GREEN)Database dumped to backup.sql$(NC)"

db-restore: ## Restore database from backup.sql
	@echo "$(YELLOW)Restoring database from backup.sql...$(NC)"
	$(DC) exec -T mariadb mysql -u $${DB_USER} -p$${DB_PASSWORD} $${DB_NAME} < backup.sql
	@echo "$(GREEN)Database restored$(NC)"

# =============================================================================
# WordPress CLI
# =============================================================================
wp: ## Run wp-cli command (usage: make wp CMD="plugin list")
	$(DC) exec -u nginx wordpress wp $(CMD)

# =============================================================================
# Environment Setup
# =============================================================================
env-check: ## Check if .env file exists
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Error: $(ENV_FILE) not found!$(NC)"; \
		echo "$(YELLOW)Run 'make setup' to create from example$(NC)"; \
		exit 1; \
	fi

setup: ## Create .env from .env.example if not exists
	@if [ ! -f $(ENV_FILE) ]; then \
		cp $(ENV_EXAMPLE) $(ENV_FILE); \
		echo "$(GREEN)Created $(ENV_FILE) from $(ENV_EXAMPLE)$(NC)"; \
		echo "$(YELLOW)Please edit $(ENV_FILE) with your settings$(NC)"; \
	else \
		echo "$(YELLOW)$(ENV_FILE) already exists$(NC)"; \
	fi

setup-dirs: ## Create volume directories from .env
	@echo "$(GREEN)Creating volume directories...$(NC)"
	@. ./$(ENV_FILE) && \
		mkdir -p "$${DATA_ROOT_PATH}/wordpress/data" \
		         "$${DATA_ROOT_PATH}/wordpress/logs" \
		         "$${DATA_ROOT_PATH}/mariadb/data" \
		         "$${DATA_ROOT_PATH}/mariadb/logs" \
		         "$${DATA_ROOT_PATH}/nginx/logs"

# =============================================================================
# Health & Debug
# =============================================================================
health: ## Check container health status
	@echo "$(GREEN)Container Health Status:$(NC)"
	@$(DC) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

nginx-test: ## Test nginx configuration
	$(DC) exec nginx nginx -t

# =============================================================================
# Help
# =============================================================================
help: ## Show this help
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

.PHONY: all up down stop start restart build build-no-cache \
        clean fclean re \
        ps logs logs-wp logs-db logs-nginx \
        shell-wp shell-db shell-nginx \
        db-cli db-dump db-restore \
        wp \
        env-check setup setup-dirs \
        health nginx-test \
        help

.DEFAULT_GOAL := help
