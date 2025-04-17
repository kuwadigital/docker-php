ARG REDIS_VERSION
FROM redis:${REDIS_VERSION}-alpine

# Copie du fichier de configuration Redis
COPY redis.conf /usr/local/etc/redis/redis.conf

# Lancement du serveur Redis avec notre fichier de configuration
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
