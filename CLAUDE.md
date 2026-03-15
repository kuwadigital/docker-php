# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-based PHP development environment (app wrapper) with multi-database support (MySQL, PostgreSQL, MongoDB), Redis caching, RabbitMQ messaging, Mailpit email testing, and Adminer database admin UI. The `src/` directory is a mount point where any major PHP framework can be installed via `make init-[framework]-app` commands. All services are orchestrated via Docker Compose with profiles.

## Setup

```bash
cp docker/.env.example docker/.env   # Create local env config
# Edit docker/.env to set COMPOSE_PROJECT_NAME and APP_PORT (see Multi-Instance below)
make docker-build                     # Build all Docker images
make docker-start-mysql               # Start environment
# Open http://localhost → default landing page
```

### Multi-Instance Setup

To run multiple instances simultaneously (e.g., different frameworks side by side), each clone needs a unique `COMPOSE_PROJECT_NAME` and non-conflicting ports in `docker/.env`:

```env
# Instance 1 (default)
COMPOSE_PROJECT_NAME=app1
APP_PORT=80

# Instance 2
COMPOSE_PROJECT_NAME=app2
APP_PORT=8080
MYSQL_PORT=3316
MYSQL_TEST_PORT=3317
REDIS_PORT=6389
ADMINER_PORT=8091
PORT_MAIL_SMTP=1035
PORT_MAIL_HTTP=8035
PORT_RABBITMQ_LISTENER=5682
PORT_RABBITMQ_TCP_LISTENER=5683
PORT_RABBITMQ_MANAGEMENT=15682
```

`COMPOSE_PROJECT_NAME` isolates containers, volumes, and networks per instance. All ports must be unique across instances to avoid conflicts.

## Common Commands

All operations go through Make. Run `make help` to see all available commands.

### Build & Run

```bash
make docker-build              # Build all Docker images
make docker-start-mysql        # Start with MySQL profile
make docker-start-postgres     # Start with PostgreSQL profile
make docker-start-mongo        # Start with MongoDB profile
make docker-stop               # Stop containers
make docker-down               # Stop and remove containers (keeps volumes)
make docker-clean              # Full reset including volumes
```

### Framework Init

```bash
make init-laravel-app          # Install Laravel (VERSION=11.*)
make init-laravel-api          # Install Laravel API + API Platform + Book example
make init-symfony-app          # Install Symfony (VERSION=7.*)
make init-symfony-api          # Install Symfony API + API Platform + Book example
make init-codeigniter-app      # Install CodeIgniter 4 (VERSION=4.*)
make init-cakephp-app          # Install CakePHP (VERSION=5.*)
make init-slim-app             # Install Slim Framework (VERSION=4.*)
make init-laminas-app          # Install Laminas MVC
make init-reset                # Reset to default landing page
```

All init commands accept `CONFIRM=yes` to skip the interactive prompt. An optional `VERSION=x.x` can be passed to pin a specific version.

### Application

```bash
make app-composer-install      # Install PHP dependencies
make app-composer-update       # Update PHP dependencies
make app-test                  # Run PHPUnit tests
```

### Database CLI & Import/Export

```bash
make docker-mysql-cli          # MySQL shell
make docker-psql-cli           # PostgreSQL shell
make docker-mongo-cli          # MongoDB shell
make docker-redis-cli          # Redis shell
make app-db-mysql-import       # Import db/db.sql into MySQL
make app-db-mysql-export       # Export MySQL to db/db.sql
make app-db-psql-import        # Import db/db.sql into PostgreSQL
make app-db-psql-export        # Export PostgreSQL to db/db.sql
# Test DB variants use `-test-` infix (e.g., app-db-mysql-test-import)
```

### Container Access & Logs

```bash
make docker-shell-php          # PHP container shell (www-data)
make docker-shell-root-php     # PHP container shell (root)
make docker-logs               # Stream all container logs
make docker-ps                 # List running containers
```

## Architecture

### Service Topology

- **Nginx 1.27** (port 80) → reverse-proxies to **PHP-FPM** (port 9000)
- **PHP 8.3** has all DB drivers installed (PDO MySQL/PostgreSQL, MySQLi, MongoDB, Redis, AMQP) plus GD, ZIP, intl, mbstring, OPcache, Xdebug
- Databases run as separate containers with **primary + test instance** pairs (e.g., MySQL on 3306, MySQL test on 3307)
- Services communicate over an explicit `app-network` Docker bridge network
- Dev tools (Adminer, Mailpit, RabbitMQ) are in the `dev` profile, auto-started with `make docker-start-*`

### Docker Compose Profiles

- Database profiles: `mysql`, `postgres`, `mongo` — activated by `make docker-start-*`
- Dev profile: `dev` — contains Adminer, Mailpit, RabbitMQ (auto-included)

### Nginx Templates

- `docker/nginx/templates/public.conf.template` — document root `/var/www/html/public` (Laravel, Symfony, CI4, Slim, Laminas, default)
- `docker/nginx/templates/webroot.conf.template` — document root `/var/www/html/webroot` (CakePHP)
- Active config: `docker/nginx/conf.d/app.conf` (gitignored, copied from template by init commands)

### Key Directories

- `docker/` — All Docker configuration (Compose file, `.env.example`, per-service Dockerfiles and configs)
- `docker/nginx/templates/` — Nginx config templates for different frameworks
- `src/` — PHP application source, mounted at `/var/www/html` in containers
- `src/public/` — Default document root (landing page when no framework installed)
- `db/` — Database dump files (SQL for MySQL/PostgreSQL, JSON for MongoDB)

### Debugging

Xdebug 3 is preconfigured for PhpStorm (IDE key: `PHPSTORM`, port 9003). Enable by setting `XDEBUG_MODE=debug` in `docker/.env` (default: `off`).

### Port Map (defaults from docker/.env.example)

| Service | Port |
|---|---|
| Nginx | 80 |
| MySQL / test | 3306 / 3307 |
| PostgreSQL / test | 5432 / 15432 |
| MongoDB / test | 27017 / 27018 |
| Redis | 6379 |
| Adminer | 8081 |
| Mailpit (SMTP / UI) | 1025 / 8025 |
| RabbitMQ (AMQP / Management) | 5672 / 15672 |
