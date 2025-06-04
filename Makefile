# Makefile

# Load environment variables
-include backend/.env
-include frontend/.env
-include db/.env

# Directories
BACKEND_DIR=backend
FRONTEND_DIR=frontend
DOCKER_COMPOSE=docker-compose -f docker-compose.prod.yml

# Help
.PHONY: help
help:
	@echo "Available commands:"
	@awk '/^[a-zA-Z_-]+:/{split($$1, target, ":"); print "  " target[1] "\t" substr($$0, index($$0,$$2))}' $(MAKEFILE_LIST)

# ============= BACKEND ===================
.PHONY: start-backend test-backend

start-backend: ## Start the backend server locally
	cd $(BACKEND_DIR) && ./start.sh

test-backend: ## Run backend tests
	cd $(BACKEND_DIR) && uv run pytest


# ============= FRONTEND ===================
.PHONY: start-frontend test-frontend

start-frontend: ## Start the frontend server locally
	cd $(FRONTEND_DIR) && ./start.sh

test-frontend: ## Run frontend tests
	cd $(FRONTEND_DIR) && npm run test


# ============= DOCKER COMMANDS ==============
.PHONY: docker-up docker-down docker-build docker-rebuild docker-logs

docker-up: ## Start all services
	$(DOCKER_COMPOSE) up -d

docker-down: ## Stop all services
	$(DOCKER_COMPOSE) down

docker-build: ## Build all Docker images
	$(DOCKER_COMPOSE) build

docker-rebuild: ## Force rebuild all images
	$(DOCKER_COMPOSE) build --no-cache

docker-logs: ## Tail logs from all services
	$(DOCKER_COMPOSE) logs -f

# ============= SHELLS ==============
.PHONY: docker-shell-backend docker-shell-frontend

docker-shell-backend: ## Shell into backend container
	$(DOCKER_COMPOSE) exec backend sh

docker-shell-frontend: ## Shell into frontend container
	$(DOCKER_COMPOSE) exec frontend sh


# ============= DB MANAGEMENT ==============
.PHONY: backup-db restore-db

backup-db: ## Backup database to ./db/backup.sql
	docker exec $$(docker-compose -f docker-compose.prod.yml ps -q db) sh -c 'exec mysqldump -uroot -p$$MYSQL_ROOT_PASSWORD $$MYSQL_DATABASE' > ./db/backup.sql

restore-db: ## Restore ./db/backup.sql into database
	cat ./db/backup.sql | docker exec -i $$(docker-compose -f docker-compose.prod.yml ps -q db) sh -c 'exec mysql -uroot -p$$MYSQL_ROOT_PASSWORD $$MYSQL_DATABASE'

# ============= CI/CD ==============
.PHONY: deploy

deploy: docker-build ## Deploy to VPS (edit with your server)
	scp docker-compose.prod.yml user@your-vps:/home/user/
	ssh user@your-vps 'docker-compose -f /home/user/docker-compose.prod.yml up -d --build'