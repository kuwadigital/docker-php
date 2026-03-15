# Docker PHP Environment

Environnement de développement Docker complet pour applications PHP avec support multi-bases de données (MySQL, PostgreSQL, MongoDB), cache Redis, messaging RabbitMQ, test email Mailpit et administration Adminer. Le répertoire `src/` est un point de montage où tout framework PHP majeur peut être installé via les commandes `make init-*`.

## Sommaire

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Multi-Instance](#multi-instance)
- [Démarrage de l'environnement](#démarrage-de-lenvironnement)
- [Arrêt et nettoyage](#arrêt-et-nettoyage)
- [Initialisation de framework](#initialisation-de-framework)
- [Commandes applicatives](#commandes-applicatives)
- [Accès aux conteneurs et logs](#accès-aux-conteneurs-et-logs)
- [Gestion des bases de données](#gestion-des-bases-de-données)
- [Tests](#tests)
- [Services de développement](#services-de-développement)
- [Débogage (Xdebug)](#débogage-xdebug)
- [Architecture](#architecture)
- [Ports par défaut](#ports-par-défaut)
- [Structure du projet](#structure-du-projet)

---

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) (>= 20.10) avec le plugin Compose (`docker compose`)
- [Make](https://www.gnu.org/software/make/)
- (Optionnel) [Git](https://git-scm.com/)

```bash
docker --version
docker compose version
```

---

## Installation

1. **Cloner le dépôt**

```bash
git clone <url-du-repo> && cd <nom-du-repo>
```

2. **Configurer les variables d'environnement**

```bash
cp docker/.env.example docker/.env
```

Modifiez `docker/.env` selon vos besoins (ports, versions, mots de passe, etc).

3. **Construire les images Docker**

```bash
make docker-build
```

4. **Démarrer l'environnement**

```bash
make docker-start-mysql
```

Ouvrez http://localhost pour voir la page d'accueil par défaut.

---

## Multi-Instance

Pour exécuter plusieurs instances simultanément (ex : différents frameworks côte à côte), chaque clone doit avoir un `COMPOSE_PROJECT_NAME` unique et des ports distincts dans `docker/.env` :

```env
# Instance 1 (défaut)
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

`COMPOSE_PROJECT_NAME` isole les conteneurs, volumes et réseaux par instance. Tous les ports doivent être uniques entre instances.

---

## Démarrage de l'environnement

Chaque commande de démarrage active un profil de base de données + le profil `dev` (Adminer, Mailpit, RabbitMQ).

```bash
make docker-start-mysql        # MySQL
make docker-start-postgres     # PostgreSQL
make docker-start-mongo        # MongoDB
```

---

## Arrêt et nettoyage

```bash
make docker-stop               # Arrêter les conteneurs
make docker-down               # Arrêter et supprimer les conteneurs (volumes conservés)
make docker-clean              # Reset complet : conteneurs + volumes supprimés
```

---

## Initialisation de framework

Ces commandes suppriment le contenu de `src/`, installent le framework choisi et configurent automatiquement les connexions aux services Docker (base de données, Redis, mail, etc).

> Les conteneurs doivent tourner avant de lancer ces commandes (ex : `make docker-start-mysql`).

### Applications web

```bash
make init-laravel-app          # Laravel (VERSION=11.* par défaut)
make init-symfony-app          # Symfony (VERSION=7.* par défaut)
make init-codeigniter-app      # CodeIgniter 4 (VERSION=4.* par défaut)
make init-cakephp-app          # CakePHP (VERSION=5.* par défaut)
make init-slim-app             # Slim Framework (VERSION=4.* par défaut)
make init-laminas-app          # Laminas MVC
```

### APIs avec API Platform

```bash
make init-laravel-api          # Laravel + API Platform + exemple Book
make init-symfony-api          # Symfony + API Platform + Doctrine + exemple Book
```

Les APIs installent une entité `Book` d'exemple avec les endpoints REST accessibles sur `/api/books` et la documentation Swagger sur `/api/docs`.

### Reset

```bash
make init-reset                # Revenir à la page d'accueil par défaut
```

### Options

- `CONFIRM=yes` : passer la confirmation interactive (ex : `make init-laravel-app CONFIRM=yes`)
- `VERSION=x.*` : fixer une version spécifique (ex : `make init-symfony-app VERSION=6.*`)

---

## Commandes applicatives

```bash
make app-composer-install      # Installer les dépendances PHP (Composer)
make app-composer-update       # Mettre à jour les dépendances PHP
make app-test                  # Exécuter les tests PHPUnit
```

---

## Accès aux conteneurs et logs

```bash
make docker-shell-php          # Shell PHP (www-data)
make docker-shell-root-php     # Shell PHP (root)
make docker-logs               # Logs de tous les conteneurs
make docker-ps                 # Lister les conteneurs actifs
```

---

## Gestion des bases de données

### CLI

```bash
make docker-mysql-cli          # Shell MySQL
make docker-psql-cli           # Shell PostgreSQL
make docker-mongo-cli          # Shell MongoDB
make docker-redis-cli          # Shell Redis
```

### Import / Export

```bash
make app-db-mysql-import       # Importer db/db.sql dans MySQL
make app-db-mysql-export       # Exporter MySQL vers db/db.sql
make app-db-psql-import        # Importer db/db.sql dans PostgreSQL
make app-db-psql-export        # Exporter PostgreSQL vers db/db.sql
```

### Import / Export (bases de test)

```bash
make app-db-mysql-test-import  # Importer db/db_test.sql dans MySQL test
make app-db-mysql-test-export  # Exporter MySQL test vers db/db_test.sql
make app-db-psql-test-import   # Importer db/db_test.sql dans PostgreSQL test
make app-db-psql-test-export   # Exporter PostgreSQL test vers db/db_test.sql
```

---

## Tests

Chaque profil de base de données démarre automatiquement une instance de test dédiée (ex : `mysql_test` sur le port 3307). Les tests PHPUnit s'exécutent via :

```bash
make app-test
```

---

## Services de développement

Les services suivants sont inclus dans le profil `dev` et démarrent automatiquement avec `make docker-start-*`.

### Adminer

Interface web d'administration de bases de données.

```
http://localhost:8081
```

### Mailpit

Capture les emails envoyés par l'application (SMTP sur le port 1025).

```
http://localhost:8025
```

### RabbitMQ

Broker de messages avec interface de management.

```
http://localhost:15672
```

---

## Débogage (Xdebug)

Xdebug 3 est préconfiguré pour PhpStorm (IDE key : `PHPSTORM`, port 9003).

Pour activer le débogage, modifiez `docker/.env` :

```env
XDEBUG_MODE=debug
```

Par défaut : `XDEBUG_MODE=off`.

---

## Architecture

### Stack technique

| Service | Version |
|---|---|
| Nginx | 1.27 (Alpine) |
| PHP-FPM | 8.3 |
| MySQL | 8.4 |
| PostgreSQL | 16 |
| MongoDB | 7 |
| Redis | 7 |
| RabbitMQ | 4.0.6 |
| Adminer | 4.8.1 |
| Mailpit | latest |

### Extensions PHP

PDO MySQL, PDO PostgreSQL, MySQLi, PostgreSQL, MongoDB, Redis, AMQP, GD (freetype, jpeg, webp, xpm), ZIP, intl, mbstring, OPcache, cURL, Xdebug.

### Topologie des services

- **Nginx** (port 80) → reverse-proxy vers **PHP-FPM** (port 9000)
- Les bases de données tournent en conteneurs séparés avec une paire **primaire + test** (ex : MySQL sur 3306, MySQL test sur 3307)
- Les services communiquent via un réseau Docker bridge `app-network`

### Profils Docker Compose

- Bases de données : `mysql`, `postgres`, `mongo` — activés par `make docker-start-*`
- Dev : `dev` — contient Adminer, Mailpit, RabbitMQ (inclus automatiquement)

### Templates Nginx

- `docker/nginx/templates/public.conf.template` — document root `/var/www/html/public` (Laravel, Symfony, CI4, Slim, Laminas, page par défaut)
- `docker/nginx/templates/webroot.conf.template` — document root `/var/www/html/webroot` (CakePHP)

La configuration active est copiée dans `docker/nginx/conf.d/app.conf` (gitignored) par les commandes `init-*`.

---

## Ports par défaut

| Service | Port |
|---|---|
| Nginx (HTTP) | 80 |
| MySQL / test | 3306 / 3307 |
| PostgreSQL / test | 5432 / 15432 |
| MongoDB / test | 27017 / 27018 |
| Redis | 6379 |
| Adminer | 8081 |
| Mailpit (SMTP / UI) | 1025 / 8025 |
| RabbitMQ (AMQP / TCP / Management) | 5672 / 5673 / 15672 |

Tous les ports sont configurables dans `docker/.env`.

---

## Structure du projet

```
├── Makefile                          # Toutes les commandes make
├── docker/
│   ├── docker-compose.yml            # Orchestration des services
│   ├── .env.example                  # Variables d'environnement (template)
│   ├── default-landing.php           # Page d'accueil par défaut
│   ├── php/                          # Dockerfile PHP + config (php.ini, xdebug.ini)
│   ├── nginx/
│   │   ├── conf.d/                   # Config active (gitignored)
│   │   └── templates/                # Templates Nginx (public, webroot)
│   ├── mysql/                        # Dockerfile MySQL
│   ├── postgres/                     # Dockerfile PostgreSQL
│   ├── mongo/                        # Dockerfile MongoDB
│   ├── redis/                        # Dockerfile Redis
│   ├── scaffolds/                    # Fichiers modèles pour les APIs
│   │   ├── laravel-api/              # Modèle Book pour Laravel API
│   │   └── symfony-api/              # Entité Book pour Symfony API
│   └── logs/nginx/                   # Logs Nginx (access.log, error.log)
├── src/                              # Code source PHP (monté dans /var/www/html)
│   └── public/                       # Document root par défaut
└── db/                               # Dumps de bases de données (SQL, JSON)
```

---

## Aide

Pour voir toutes les commandes disponibles :

```bash
make help
```
