# Docker PHP Environment

Ce projet fournit un environnement de développement complet pour des applications PHP avec support multi-base de données (MySQL, PostgreSQL, MongoDB, Redis) via Docker Compose. Il inclut également Nginx comme serveur web et Adminer pour l'administration des bases de données.

## Sommaire
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Démarrage de l'environnement](#démarrage-de-lenvironnement)
- [Arrêt et nettoyage](#arrêt-et-nettoyage)
- [Accès aux conteneurs et logs](#accès-aux-conteneurs-et-logs)
- [Commandes applicatives](#commandes-applicatives)
- [Gestion des bases de données](#gestion-des-bases-de-données)
- [Tests](#tests)
- [Adminer](#adminer)
- [Volumes Docker](#volumes-docker)
- [Astuces et Dépannage](#astuces-et-dépannage)

---

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) (>= 20.10)
- [Docker Compose](https://docs.docker.com/compose/install/) (>= 1.29)
- [Make](https://www.gnu.org/software/make/)
- (Optionnel) [Git](https://git-scm.com/)

Assurez-vous que Docker et Docker Compose sont installés et fonctionnels :

```bash
docker --version
docker-compose --version
```

---

## Installation

1. **Cloner le dépôt**

```bash
git clone <url-du-repo> && cd docker-php
```

2. **Configurer les variables d'environnement**

Copiez le fichier d'exemple si besoin :

```bash
cp docker/.env.example docker/.env
```

Modifiez `docker/.env` selon vos besoins (ports, versions, mots de passe, etc).

3. **Construire les images Docker**

```bash
make docker-build
```

---

## Démarrage de l'environnement

Par défaut, l'environnement démarre avec MySQL. Pour démarrer avec une autre base, utilisez le profil correspondant.

- **MySQL (par défaut)** :

```bash
make docker-start
```

- **PostgreSQL** :

```bash
make docker-start-postgres
```

- **MongoDB** :

```bash
make docker-start-mongo
```

Pour arrêter :

```bash
make docker-stop
```

Pour arrêter et supprimer les conteneurs (sans supprimer les volumes) :

```bash
make docker-down
```

Pour un reset complet (suppression des volumes) :

```bash
make docker-clean
```

---

## Accès aux conteneurs et logs

- **Shell PHP** :

```bash
make docker-shell-php
```

- **Logs de tous les services** :

```bash
make docker-logs
```

- **Lister les conteneurs actifs** :

```bash
make docker-ps
```

---

## Commandes applicatives

- **Installer les dépendances PHP (Composer)** :

```bash
make app-composer-install
```

- **Mettre à jour les dépendances PHP** :

```bash
make app-composer-update
```

---

## Gestion des bases de données

### MySQL

- **Client MySQL** :

```bash
make docker-mysql-cli
```

- **Importer un dump** :

```bash
make app-db-mysql-import
```

- **Exporter la base** :

```bash
make app-db-mysql-export
```

### PostgreSQL

- **Client PostgreSQL** :

```bash
make docker-psql-cli
```

- **Importer un dump** :

```bash
make app-db-psql-import
```

- **Exporter la base** :

```bash
make app-db-psql-export
```

### MongoDB

- **Client MongoDB** :

```bash
make docker-mongo-cli
```

### Redis

- **Client Redis** :

```bash
make docker-redis-cli
```

---

## Tests

- **Exécuter les tests PHPUnit** :

```bash
make app-test
```

- **Bases de test (import/export/cli)** :

Voir les commandes :

```bash
make help
```

Exemples :

- Importer un dump de test MySQL :

```bash
make app-db-mysql-test-import
```

- Exporter la base de test PostgreSQL :

```bash
make app-db-psql-test-export
```

---

## Adminer

Adminer est accessible sur le port `${ADMINER_PORT}` (défini dans `docker/.env`).

Ouvrez :

```
http://localhost:<ADMINER_PORT>
```

---

## Volumes Docker

Les données des bases sont persistées dans les volumes Docker suivants :

- `mysql_data`, `postgres_data`, `mongo_data`, `redis_data`
- Volumes de test : `mysql_test_data`, `postgres_test_data`, `mongo_test_data`

---

## Astuces et Dépannage

- Pour voir toutes les commandes disponibles :

```bash
make help
```

- Pour reconstruire une image spécifique :

```bash
docker-compose build <service>
```

- Pour accéder à un service en shell :

```bash
docker-compose exec <service> bash
```

- Pour supprimer tous les volumes (reset total) :

```bash
make docker-clean
```

---

## Structure du projet

```
docker-compose.yml
Makefile
docker/
  php/ nginx/ mysql/ postgres/ mongo/ redis/
src/
db/
```

---

## Remarques

- Les ports, utilisateurs, mots de passe, etc. sont configurables dans `docker/.env`.
- Les dumps SQL doivent être placés dans le dossier `db/`.
- Les logs Nginx sont dans `docker/logs/nginx/`.

---

Pour toute question, consultez le Makefile ou ouvrez une issue sur le dépôt.

## Configuration Nginx pour public.local

L'environnement Nginx est préconfiguré pour servir le domaine `public.local`.

- **Fichier de configuration** : `docker/nginx/conf.d/public.conf`
- **Racine du site** : `/var/www/html/public` (correspond à `./src/public` dans le projet)
- **Accès** :
    - Le serveur écoute sur le port 80 du conteneur (mappé sur `${APP_PORT}` côté hôte).
    - Le nom de domaine attendu est `public.local`.

### Ajouter public.local à votre fichier hosts

Pour accéder à l'application via http://public.local, ajoutez la ligne suivante à votre `/etc/hosts` :

```
127.0.0.1   public.local
```

> **Note** : Sur certains systèmes, il peut être nécessaire d'utiliser `sudo` pour éditer ce fichier.

### Structure de la configuration Nginx

- **Fichiers statiques** : Servis directement (images, CSS, JS, etc.)
- **PHP** : Les requêtes `.php` sont transmises au conteneur PHP-FPM
- **Fallback** : Toute autre requête est redirigée vers `index.php` (utile pour les frameworks modernes)
- **Logs** :
    - Accès : `docker/logs/nginx/access.log`
    - Erreurs : `docker/logs/nginx/error.log`

Pour toute modification, éditez le fichier `docker/nginx/conf.d/public.conf` puis redémarrez le service Nginx :

```bash
docker-compose restart nginx
```
