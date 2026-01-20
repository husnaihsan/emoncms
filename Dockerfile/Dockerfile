# Repo: https://github.com/husnaihsan/emoncms.git

FROM php:8.2-apache

WORKDIR /var/www/html

# Apache config: rewrite + allow .htaccess
RUN a2enmod rewrite \
 && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# System packages: DB, redis, mqtt, supervisor, python3, build tools for pecl
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    redis-server \
    mosquitto mosquitto-clients \
    supervisor \
    python3 \
    curl \
    git unzip zip \
    $PHPIZE_DEPS \
 && rm -rf /var/lib/apt/lists/*

# PHP extensions required by EmonCMS (minimum useful set)
RUN docker-php-ext-install mysqli gettext

# PHP Redis extension (phpredis)
RUN pecl install redis \
 && docker-php-ext-enable redis

# Copy EmonCMS source code
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

# Copy our container configs
COPY Dockerfile/settings.ini /var/www/html/settings.ini
COPY Dockerfile/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY Dockerfile/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create datadirs used by settings.ini
RUN mkdir -p /var/opt/emoncms/phpfina /var/opt/emoncms/phptimeseries \
 && chown -R www-data:www-data /var/opt/emoncms

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
