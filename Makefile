# Charger les variables d'environnement Docker (si le fichier existe)
ifneq (,$(wildcard docker/.env))
include docker/.env
export $(shell sed -e 's/=.*//' docker/.env)
endif

# ——— Commandes de build et démarrage ———

docker-build:        ## Construire les images Docker (PHP, Nginx, DB, etc.)
	docker-compose build

# Démarrage de l'environnement

docker-start: docker-start-mysql   ## Démarrer l'environnement avec MySQL (par défaut)
	@echo "Environment started with MySQL (default)."

docker-start-mysql:         ## Démarrer l'environnement avec MySQL comme DB
	COMPOSE_PROFILES=mysql docker-compose up -d

docker-start-postgres:      ## Démarrer l'environnement avec PostgreSQL comme DB
	COMPOSE_PROFILES=postgres docker-compose up -d

docker-start-mongo:         ## Démarrer l'environnement avec MongoDB comme DB
	COMPOSE_PROFILES=mongo docker-compose up -d

docker-stop:           ## Arrêter les conteneurs
	docker-compose stop

docker-down:           ## Arrêter et supprimer les conteneurs (sans supprimer les volumes)
	docker-compose down

# ——— Commandes d'accès aux conteneurs ———

docker-shell-php:     ## Ouvrir un shell bash à l'intérieur du conteneur PHP
	docker-compose exec php bash

docker-logs:          ## Suivre les logs de tous les services
	docker-compose logs -f --tail=100

docker-ps:            ## Lister les conteneurs en cours d'exécution (projet courant)
	docker-compose ps

# ——— Commandes applicatives ———

app-composer-install:   ## Installer les dépendances PHP via Composer
	docker-compose exec php composer install

app-composer-update:    ## Mettre à jour les dépendances PHP via Composer
	docker-compose exec php composer update

app-test:          ## Exécuter les tests PHPUnit dans le conteneur PHP
	docker-compose exec php php vendor/bin/phpunit

# ——— Commandes base de données ———

app-db-mysql-import:     ## Importer le fichier db/db.sql dans la base de données (MySQL par défaut)
	@[ -f db/db.sql ] || (echo "Le fichier db/db.sql est introuvable" && exit 1)
	docker-compose exec -T mysql sh -c 'exec mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' < db/db.sql
	@echo "Import SQL terminé depuis db/db.sql."

app-db-mysql-export:     ## Exporter la base de données dans db/db.sql (MySQL par défaut)
	docker-compose exec -T mysql sh -c 'exec mysqldump -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' > db/db.sql
	@echo "Dump SQL enregistré dans db/db.sql."

docker-mysql-cli:     ## Ouvrir un client MySQL (shell)
	docker-compose exec mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

docker-psql-cli:      ## Ouvrir un client PostgreSQL (shell)
	docker-compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

docker-mongo-cli:     ## Ouvrir le shell MongoDB (mongosh)
	docker-compose exec mongo mongosh -u $(MONGO_INITDB_ROOT_USERNAME) -p $(MONGO_INITDB_ROOT_PASSWORD) --authenticationDatabase admin

docker-redis-cli:     ## Ouvrir un shell Redis
	docker-compose exec redis redis-cli

# ——— Autres ———

docker-clean:         ## Arrêter l'environnement et supprimer les volumes (reset complet de l'environnement)
	docker-compose down -v

# Commandes pour les bases de données de test

app-db-mysql-test-import:     ## Importer le fichier db/db_test.sql dans la base de données de test (MySQL)
	@[ -f db/db_test.sql ] || (echo "Le fichier db/db_test.sql est introuvable" && exit 1)
	docker-compose exec -T mysql_test sh -c 'exec mysql -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' < db/db_test.sql
	@echo "Import SQL (test) terminé depuis db/db_test.sql."

app-db-mysql-test-export:     ## Exporter la base de données de test dans db/db_test.sql (MySQL)
	docker-compose exec -T mysql_test sh -c 'exec mysqldump -uroot -p"$$MYSQL_ROOT_PASSWORD" "$$MYSQL_DATABASE"' > db/db_test.sql
	@echo "Dump SQL (test) enregistré dans db/db_test.sql."

docker-mysql-test-cli:     ## Ouvrir un client MySQL (shell) sur la base de test
	docker-compose exec mysql_test mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

docker-psql-test-cli:      ## Ouvrir un client PostgreSQL (shell) sur la base de test
	docker-compose exec postgres_test psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

docker-mongo-test-cli:     ## Ouvrir le shell MongoDB (mongosh) sur la base de test
	docker-compose exec mongo_test mongosh -u $(MONGO_INITDB_ROOT_USERNAME) -p $(MONGO_INITDB_ROOT_PASSWORD) --authenticationDatabase admin

app-db-psql-import:     ## Importer le fichier db/db.sql dans la base de données PostgreSQL
	@[ -f db/db.sql ] || (echo "Le fichier db/db.sql est introuvable" && exit 1)
	docker-compose exec -T postgres sh -c 'psql -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' < db/db.sql
	@echo "Import SQL PostgreSQL terminé depuis db/db.sql."

app-db-psql-export:     ## Exporter la base de données PostgreSQL dans db/db.sql
	docker-compose exec -T postgres sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db.sql
	@echo "Dump SQL PostgreSQL enregistré dans db/db.sql."

app-db-psql-test-import:     ## Importer le fichier db/db_test.sql dans la base de données de test PostgreSQL
	@[ -f db/db_test.sql ] || (echo "Le fichier db/db_test.sql est introuvable" && exit 1)
	docker-compose exec -T postgres_test sh -c 'psql -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' < db/db_test.sql
	@echo "Import SQL PostgreSQL (test) terminé depuis db/db_test.sql."

app-db-psql-test-export:     ## Exporter la base de données de test PostgreSQL dans db/db_test.sql
	docker-compose exec -T postgres_test sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db_test.sql
	@echo "Dump SQL PostgreSQL (test) enregistré dans db/db_test.sql."

app-app-db-psql-test-export:     ## Exporter la base de données de test PostgreSQL dans db/db_test.sql
	docker-compose exec -T postgres_test sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db_test.sql
	@echo "Dump SQL PostgreSQL (test) enregistré dans db/db_test.sql."

app-db-psql-test-export:     ## Exporter la base de données de test PostgreSQL dans db/db_test.sql
	docker-compose exec -T postgres_test sh -c 'pg_dump -U "$(POSTGRES_USER)" -d "$(POSTGRES_DB)"' > db/db_test.sql
	@echo "Dump SQL PostgreSQL (test) enregistré dans db/db_test.sql."
