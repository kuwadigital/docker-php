ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

ARG UID=1000
ARG GID=1000

RUN groupmod -g ${GID} www-data \
    && usermod -u ${UID} -g ${GID} www-data \
    && chown -R www-data:www-data /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    zip \
    git \
    libicu-dev \
    libzip-dev \
    libpq-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    libcurl4-openssl-dev \
    librabbitmq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install -j$(nproc) \
        intl \
        zip \
        pdo_mysql \
        pdo_pgsql \
        mysqli \
        pgsql \
        opcache \
        mbstring \
        gd \
        curl \
    && pecl install xdebug redis mongodb amqp \
    && docker-php-ext-enable xdebug redis mongodb amqp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
