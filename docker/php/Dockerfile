# Choix de l'image de base PHP (version définie par argument)
ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

# Access utilisateur
ARG UID=1000
ARG GID=1000

RUN groupmod -g ${GID} www-data \
    && usermod -u ${UID} -g ${GID} www-data \
    && chown -R www-data:www-data /var/www/html

# Installation des extensions PHP et de Xdebug

RUN apt-get update && apt-get install -y \
    unzip \
    zip \
    git \
    libicu-dev \
    libzip-dev \
    && docker-php-ext-install intl zip

RUN apt-get update && apt-get install -y libpq-dev \ 
    && docker-php-ext-install pdo_mysql pdo_pgsql opcache intl\ 
    && pecl install xdebug && docker-php-ext-enable xdebug \ 
    && rm -rf /var/lib/apt/lists/*

# Install dependencies for PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install \
    mysqli \
    pgsql


# Copie des fichiers de configuration PHP dans l'image
COPY php.ini /usr/local/etc/php/conf.d/99-overrides.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/99-xdebug.ini

# Installation de Composer (via une image intermédiaire officielle)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
