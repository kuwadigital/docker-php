# Check for docker/.env — copy from .env.example if missing
ifeq (,$(wildcard docker/.env))
$(warning ⚠ docker/.env not found. Run: cp docker/.env.example docker/.env)
else
include docker/.env
export $(shell sed -e 's/=.*//' docker/.env)
endif

DOCKER_COMPOSE = docker compose -f ./docker/docker-compose.yml
EXEC_PHP = $(DOCKER_COMPOSE) exec php
EXEC_PHP_ROOT = $(DOCKER_COMPOSE) exec --user root php

.DEFAULT_GOAL := help

# ——— Help ———

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ——— Build & Run ———

.PHONY: docker-build
docker-build: ## Build all Docker images
	$(DOCKER_COMPOSE) build

.PHONY: docker-start
docker-start: docker-start-mysql ## Start environment with MySQL (default)

.PHONY: docker-start-mysql
docker-start-mysql: ## Start environment with MySQL
	COMPOSE_PROFILES=mysql,dev $(DOCKER_COMPOSE) up -d

.PHONY: docker-start-postgres
docker-start-postgres: ## Start environment with PostgreSQL
	COMPOSE_PROFILES=postgres,dev $(DOCKER_COMPOSE) up -d

.PHONY: docker-start-mongo
docker-start-mongo: ## Start environment with MongoDB
	COMPOSE_PROFILES=mongo,dev $(DOCKER_COMPOSE) up -d

.PHONY: docker-stop
docker-stop: ## Stop containers
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) stop

.PHONY: docker-restart
docker-restart: ## Restart containers
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) restart

.PHONY: docker-down
docker-down: ## Stop and remove containers (keeps volumes)
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) down

.PHONY: docker-clean
docker-clean: ## Full reset: stop, remove containers and volumes
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) down -v

# ——— Container Access & Logs ———

.PHONY: docker-shell-php
docker-shell-php: ## Open a shell in the PHP container (www-data)
	$(DOCKER_COMPOSE) exec --user www-data php bash

.PHONY: docker-shell-root-php
docker-shell-root-php: ## Open a root shell in the PHP container
	$(DOCKER_COMPOSE) exec --user root php bash

.PHONY: docker-logs
docker-logs: ## Stream logs from all containers
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) logs -f --tail=100

.PHONY: docker-ps
docker-ps: ## List running containers
	COMPOSE_PROFILES=mysql,postgres,mongo,dev $(DOCKER_COMPOSE) ps

# ——— Application ———

.PHONY: app-composer-install
app-composer-install: ## Install PHP dependencies via Composer
	$(EXEC_PHP) composer install

.PHONY: app-composer-update
app-composer-update: ## Update PHP dependencies via Composer
	$(EXEC_PHP) composer update

.PHONY: app-test
app-test: ## Run PHPUnit tests
	$(EXEC_PHP) php vendor/bin/phpunit

# ——— Database CLI ———

.PHONY: docker-mysql-cli
docker-mysql-cli: ## Open MySQL shell
	$(DOCKER_COMPOSE) exec mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

.PHONY: docker-psql-cli
docker-psql-cli: ## Open PostgreSQL shell
	$(DOCKER_COMPOSE) exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

.PHONY: docker-mongo-cli
docker-mongo-cli: ## Open MongoDB shell
	$(DOCKER_COMPOSE) exec mongo mongosh -u $(MONGO_INITDB_ROOT_USERNAME) -p $(MONGO_INITDB_ROOT_PASSWORD) --authenticationDatabase admin

.PHONY: docker-redis-cli
docker-redis-cli: ## Open Redis shell
	$(DOCKER_COMPOSE) exec redis redis-cli

.PHONY: docker-mysql-test-cli
docker-mysql-test-cli: ## Open MySQL test shell
	$(DOCKER_COMPOSE) exec mysql_test mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

.PHONY: docker-psql-test-cli
docker-psql-test-cli: ## Open PostgreSQL test shell
	$(DOCKER_COMPOSE) exec postgres_test psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

.PHONY: docker-mongo-test-cli
docker-mongo-test-cli: ## Open MongoDB test shell
	$(DOCKER_COMPOSE) exec mongo_test mongosh -u $(MONGO_INITDB_ROOT_USERNAME) -p $(MONGO_INITDB_ROOT_PASSWORD) --authenticationDatabase admin

# ——— Database Import/Export ———

.PHONY: app-db-mysql-import
app-db-mysql-import: ## Import db/db.sql into MySQL
	@[ -f db/db.sql ] || (echo "File db/db.sql not found" && exit 1)
	$(DOCKER_COMPOSE) exec -T mysql sh -c 'exec mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' < db/db.sql
	@echo "MySQL import completed from db/db.sql."

.PHONY: app-db-mysql-export
app-db-mysql-export: ## Export MySQL to db/db.sql
	$(DOCKER_COMPOSE) exec -T mysql sh -c 'exec mysqldump -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' > db/db.sql
	@echo "MySQL dump saved to db/db.sql."

.PHONY: app-db-mysql-test-import
app-db-mysql-test-import: ## Import db/db_test.sql into MySQL test
	@[ -f db/db_test.sql ] || (echo "File db/db_test.sql not found" && exit 1)
	$(DOCKER_COMPOSE) exec -T mysql_test sh -c 'exec mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' < db/db_test.sql
	@echo "MySQL test import completed from db/db_test.sql."

.PHONY: app-db-mysql-test-export
app-db-mysql-test-export: ## Export MySQL test to db/db_test.sql
	$(DOCKER_COMPOSE) exec -T mysql_test sh -c 'exec mysqldump -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' > db/db_test.sql
	@echo "MySQL test dump saved to db/db_test.sql."

.PHONY: app-db-psql-import
app-db-psql-import: ## Import db/db.sql into PostgreSQL
	@[ -f db/db.sql ] || (echo "File db/db.sql not found" && exit 1)
	$(DOCKER_COMPOSE) exec -T postgres sh -c 'psql -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' < db/db.sql
	@echo "PostgreSQL import completed from db/db.sql."

.PHONY: app-db-psql-export
app-db-psql-export: ## Export PostgreSQL to db/db.sql
	$(DOCKER_COMPOSE) exec -T postgres sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db.sql
	@echo "PostgreSQL dump saved to db/db.sql."

.PHONY: app-db-psql-test-import
app-db-psql-test-import: ## Import db/db_test.sql into PostgreSQL test
	@[ -f db/db_test.sql ] || (echo "File db/db_test.sql not found" && exit 1)
	$(DOCKER_COMPOSE) exec -T postgres_test sh -c 'psql -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' < db/db_test.sql
	@echo "PostgreSQL test import completed from db/db_test.sql."

.PHONY: app-db-psql-test-export
app-db-psql-test-export: ## Export PostgreSQL test to db/db_test.sql
	$(DOCKER_COMPOSE) exec -T postgres_test sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db_test.sql
	@echo "PostgreSQL test dump saved to db/db_test.sql."

# ——— Framework Init ———

define check_php_running
	@$(DOCKER_COMPOSE) ps --status running php --format '{{.Name}}' 2>/dev/null | grep -q php || \
		(echo "Error: PHP container is not running. Start it first with: make docker-start-mysql" && exit 1)
endef

define confirm_action
	@if [ "$(CONFIRM)" != "yes" ]; then \
		printf "This will DELETE everything in src/. Continue? [y/N] "; \
		read ans; \
		case "$$ans" in [yY]*) ;; *) echo "Aborted."; exit 1;; esac; \
	fi
endef

define clean_src
	$(EXEC_PHP_ROOT) sh -c 'find /var/www/html -mindepth 1 -delete'
	$(EXEC_PHP_ROOT) chown www-data:www-data /var/www/html
endef

define fix_permissions
	$(EXEC_PHP_ROOT) chown -R www-data:www-data /var/www/html
endef

.PHONY: init-laravel-app
init-laravel-app: ## Install Laravel (VERSION=11.*)
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project laravel/laravel . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP_ROOT) chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
	$(EXEC_PHP) sed -i \
		-e 's|^#\? *DB_CONNECTION=.*|DB_CONNECTION=mysql|' \
		-e 's|^#\? *DB_HOST=.*|DB_HOST=mysql|' \
		-e 's|^#\? *DB_PORT=.*|DB_PORT=3306|' \
		-e 's|^#\? *DB_DATABASE=.*|DB_DATABASE=app_db|' \
		-e 's|^#\? *DB_USERNAME=.*|DB_USERNAME=app|' \
		-e 's|^#\? *DB_PASSWORD=.*|DB_PASSWORD=app|' \
		-e 's|^#\? *REDIS_HOST=.*|REDIS_HOST=redis|' \
		-e 's|^#\? *REDIS_PORT=.*|REDIS_PORT=6379|' \
		-e 's|^#\? *CACHE_STORE=.*|CACHE_STORE=redis|' \
		-e 's|^#\? *SESSION_DRIVER=.*|SESSION_DRIVER=redis|' \
		-e 's|^#\? *MAIL_MAILER=.*|MAIL_MAILER=smtp|' \
		-e 's|^#\? *MAIL_HOST=.*|MAIL_HOST=mailpit|' \
		-e 's|^#\? *MAIL_PORT=.*|MAIL_PORT=1025|' \
		.env
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	$(EXEC_PHP) php artisan key:generate
	@echo ""
	@echo "✔ Laravel installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-symfony-app
init-symfony-app: ## Install Symfony (VERSION=7.*)
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project symfony/skeleton . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP) sh -c 'grep -q "^DATABASE_URL=" .env && sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"mysql://app:app@mysql:3306/app_db?charset=utf8mb4\"|" .env || echo "DATABASE_URL=\"mysql://app:app@mysql:3306/app_db?charset=utf8mb4\"" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^MAILER_DSN=" .env && sed -i "s|^MAILER_DSN=.*|MAILER_DSN=smtp://mailpit:1025|" .env || echo "MAILER_DSN=smtp://mailpit:1025" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^REDIS_URL=" .env && sed -i "s|^REDIS_URL=.*|REDIS_URL=redis://redis:6379|" .env || echo "REDIS_URL=redis://redis:6379" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^MESSENGER_TRANSPORT_DSN=" .env && sed -i "s|^MESSENGER_TRANSPORT_DSN=.*|MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/messages|" .env || echo "MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/messages" >> .env'
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Symfony installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-codeigniter-app
init-codeigniter-app: ## Install CodeIgniter 4 (VERSION=4.*)
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project codeigniter4/appstarter . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP) cp env .env
	$(EXEC_PHP) sed -i \
		-e 's|^# CI_ENVIRONMENT.*|CI_ENVIRONMENT = development|' \
		-e 's|^# database.default.hostname.*|database.default.hostname = mysql|' \
		-e 's|^# database.default.database.*|database.default.database = app_db|' \
		-e 's|^# database.default.username.*|database.default.username = app|' \
		-e 's|^# database.default.password.*|database.default.password = app|' \
		-e 's|^# database.default.DBDriver.*|database.default.DBDriver = MySQLi|' \
		-e 's|^# database.default.port.*|database.default.port = 3306|' \
		.env
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ CodeIgniter 4 installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-cakephp-app
init-cakephp-app: ## Install CakePHP (VERSION=5.*)
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project --prefer-dist cakephp/app . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP) sed -i \
		-e "s|'host' => 'localhost'|'host' => 'mysql'|" \
		-e "s|'username' => 'my_app'|'username' => 'app'|" \
		-e "s|'password' => 'secret'|'password' => 'app'|" \
		-e "s|'database' => 'my_app'|'database' => 'app_db'|" \
		config/app_local.php
	cp docker/nginx/templates/webroot.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	$(EXEC_PHP) bin/cake cache clear_all
	@echo ""
	@echo "✔ CakePHP installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-slim-app
init-slim-app: ## Install Slim Framework (VERSION=4.*)
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project slim/slim-skeleton . $(or $(VERSION),)
	$(call fix_permissions)
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Slim installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-laminas-app
init-laminas-app: ## Install Laminas MVC
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project --no-interaction laminas/laminas-mvc-skeleton . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP) php -r "file_put_contents('config/autoload/local.php', '<?php' . chr(10) . 'return [' . chr(10) . '    \"db\" => [' . chr(10) . '        \"driver\" => \"Pdo_Mysql\",' . chr(10) . '        \"hostname\" => \"mysql\",' . chr(10) . '        \"database\" => \"app_db\",' . chr(10) . '        \"username\" => \"app\",' . chr(10) . '        \"password\" => \"app\",' . chr(10) . '        \"port\" => 3306,' . chr(10) . '    ],' . chr(10) . '];' . chr(10));"
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Laminas MVC installed successfully!"
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"

.PHONY: init-laravel-api
init-laravel-api: ## Install Laravel API with API Platform + Book example
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project laravel/laravel . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP_ROOT) chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
	$(EXEC_PHP) sed -i \
		-e 's|^#\? *DB_CONNECTION=.*|DB_CONNECTION=mysql|' \
		-e 's|^#\? *DB_HOST=.*|DB_HOST=mysql|' \
		-e 's|^#\? *DB_PORT=.*|DB_PORT=3306|' \
		-e 's|^#\? *DB_DATABASE=.*|DB_DATABASE=app_db|' \
		-e 's|^#\? *DB_USERNAME=.*|DB_USERNAME=app|' \
		-e 's|^#\? *DB_PASSWORD=.*|DB_PASSWORD=app|' \
		-e 's|^#\? *REDIS_HOST=.*|REDIS_HOST=redis|' \
		-e 's|^#\? *REDIS_PORT=.*|REDIS_PORT=6379|' \
		-e 's|^#\? *CACHE_STORE=.*|CACHE_STORE=redis|' \
		-e 's|^#\? *SESSION_DRIVER=.*|SESSION_DRIVER=redis|' \
		-e 's|^#\? *MAIL_MAILER=.*|MAIL_MAILER=smtp|' \
		-e 's|^#\? *MAIL_HOST=.*|MAIL_HOST=mailpit|' \
		-e 's|^#\? *MAIL_PORT=.*|MAIL_PORT=1025|' \
		.env
	$(EXEC_PHP) php artisan key:generate
	$(EXEC_PHP) composer require api-platform/laravel
	$(EXEC_PHP) php artisan api-platform:install
	$(DOCKER_COMPOSE) cp docker/scaffolds/laravel-api/Book.php php:/var/www/html/app/Models/Book.php
	$(DOCKER_COMPOSE) cp docker/scaffolds/laravel-api/create_books_table.php php:/var/www/html/database/migrations/0001_01_01_000003_create_books_table.php
	$(call fix_permissions)
	$(EXEC_PHP) php artisan migrate
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Laravel API with API Platform installed successfully!"
	@echo "  → API:  http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api"
	@echo "  → Docs: http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api/docs"
	@echo "  → Book: http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api/books"

.PHONY: init-symfony-api
init-symfony-api: ## Install Symfony API with API Platform + Book example
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP) composer create-project symfony/skeleton . $(or $(VERSION),)
	$(call fix_permissions)
	$(EXEC_PHP) composer require api
	$(EXEC_PHP) composer require symfony/orm-pack
	$(EXEC_PHP) composer require --dev symfony/maker-bundle
	$(EXEC_PHP) sh -c 'grep -q "^DATABASE_URL=" .env && sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"mysql://app:app@mysql:3306/app_db?serverVersion=8.4\&charset=utf8mb4\"|" .env || echo "DATABASE_URL=\"mysql://app:app@mysql:3306/app_db?serverVersion=8.4\&charset=utf8mb4\"" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^MAILER_DSN=" .env && sed -i "s|^MAILER_DSN=.*|MAILER_DSN=smtp://mailpit:1025|" .env || echo "MAILER_DSN=smtp://mailpit:1025" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^REDIS_URL=" .env && sed -i "s|^REDIS_URL=.*|REDIS_URL=redis://redis:6379|" .env || echo "REDIS_URL=redis://redis:6379" >> .env'
	$(EXEC_PHP) sh -c 'grep -q "^MESSENGER_TRANSPORT_DSN=" .env && sed -i "s|^MESSENGER_TRANSPORT_DSN=.*|MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/messages|" .env || echo "MESSENGER_TRANSPORT_DSN=amqp://guest:guest@rabbitmq:5672/%2f/messages" >> .env'
	$(EXEC_PHP_ROOT) mkdir -p /var/www/html/src/Entity
	$(DOCKER_COMPOSE) cp docker/scaffolds/symfony-api/Book.php php:/var/www/html/src/Entity/Book.php
	$(call fix_permissions)
	$(EXEC_PHP) php bin/console doctrine:database:create --if-not-exists
	$(EXEC_PHP) php bin/console doctrine:schema:update --force
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Symfony API with API Platform installed successfully!"
	@echo "  → API:  http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api"
	@echo "  → Docs: http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api/docs"
	@echo "  → Book: http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)/api/books"

.PHONY: init-reset
init-reset: ## Reset src/ to default landing page
	$(call check_php_running)
	$(call confirm_action)
	$(call clean_src)
	$(EXEC_PHP_ROOT) mkdir -p /var/www/html/public
	$(EXEC_PHP_ROOT) chown www-data:www-data /var/www/html/public
	cp docker/default-landing.php src/public/index.php
	cp docker/nginx/templates/public.conf.template docker/nginx/conf.d/app.conf
	$(DOCKER_COMPOSE) restart nginx
	@echo ""
	@echo "✔ Reset to default landing page."
	@echo "  → http://localhost$(if $(filter-out 80,$(APP_PORT)),:$(APP_PORT),)"
