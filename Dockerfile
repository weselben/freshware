# Stage 1: Composer Builder
FROM php:8.2-fpm-bookworm AS composer-builder
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Stage 2: Node Builder
FROM node:23.7.0-bookworm AS node-builder
RUN set -eux; \
    if ! command -v yarn >/dev/null; then \
        npm install -g yarn; \
    else \
        echo "yarn is already installed"; \
    fi; \
    yarn --version; \
    node --version; \
    npm --version

# Stage 3: Final Runtime Image
FROM php:8.2-fpm-bookworm

# Set initial user to root for installations
USER root

# Install all required system packages
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        curl gnupg libicu-dev libzip-dev libpng-dev libxml2-dev librabbitmq-dev libonig-dev \
        libcurl4-gnutls-dev libfreetype6-dev libjpeg62-turbo-dev libbz2-dev libffi-dev libgmp-dev \
        libssl-dev libzstd-dev libsoapysdr-dev autoconf gcc g++ make pkg-config re2c bison zlib1g-dev \
        libpq-dev libxslt1-dev libsqlite3-dev libpcre2-dev libedit-dev default-mysql-client git \
        gosu sudo unzip bzip2 ssmtp lsof openssh-server cron nano jq chromium xdg-utils libsodium-dev \
        libpcre3 tzdata wget mariadb-client gettext-base \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Set environment variables
ENV SW6VERSION="v6.6.10.12"
ENV FRESHWARE_VERSION="0.2.9"
ENV TZ=Europe/Berlin
ENV SW_TASKS_ENABLED=0
ENV SSH_USER=not-set
ENV SSH_PWD=not-set
ENV SW_CURRENCY=EUR
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV TASKS_STARTUP=0
ENV WORKER_STARTUP=0
ENV PATH="/usr/local/bin:/usr/sbin:${PATH}"

# Configure timezone
RUN set -eux; \
    ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Write environment variables to /etc/profile
RUN set -eux; \
    echo "export TZ=${TZ}" >> /etc/profile \
    && echo "export SW_TASKS_ENABLED=${SW_TASKS_ENABLED}" >> /etc/profile \
    && echo "export SSH_USER=${SSH_USER}" >> /etc/profile \
    && echo "export SSH_PWD=${SSH_PWD}" >> /etc/profile \
    && echo "export SW_CURRENCY=${SW_CURRENCY}" >> /etc/profile \
    && echo "export COMPOSER_ALLOW_SUPERUSER=${COMPOSER_ALLOW_SUPERUSER}" >> /etc/profile \
    && echo "export SW6VERSION=${SW6VERSION}" >> /etc/profile \
    && echo "export FRESHWARE_VERSION=${FRESHWARE_VERSION}" >> /etc/profile \
    && echo 'export PATH="/usr/local/bin:/usr/sbin:${PATH}"' >> /etc/profile \
    && echo "export TASKS_STARTUP=${TASKS_STARTUP}" >> /etc/profile \
    && echo "export WORKER_STARTUP=${WORKER_STARTUP}" >> /etc/profile

# Configure and install PHP extensions
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd curl intl mbstring pdo_mysql zip soap gmp bcmath \
    && pecl install amqp apcu zstd \
    && docker-php-ext-enable amqp apcu zstd

RUN apt install libzstd-dev && \
    pecl install --configureoptions='enable-redis-zstd="yes"' redis && \
    docker-php-ext-enable redis

# Verify required PHP extensions
RUN set -eux; \
    REQUIRED_EXTENSIONS="amqp curl dom fileinfo gd iconv intl json libxml mbstring openssl pcre pdo pdo_mysql phar simplexml xml zip zlib"; \
    for ext in $REQUIRED_EXTENSIONS; do \
        php -m | grep -i "^$ext$" || (echo "ERROR: Missing PHP extension: $ext" && exit 1); \
    done

# Copy PHP configuration files
COPY ./config/php/freshware.ini /etc/freshware/templates/php/php.ini.template
COPY ./config/php/www.conf /etc/freshware/templates/php/www.conf.template

# Copy Composer from the Composer Builder stage
COPY --from=composer-builder /usr/local/bin/composer /usr/local/bin/composer

# Copy Node.js, npm, Yarn, and global Node modules from the Node Builder stage
COPY --from=node-builder /usr/local/bin/node /usr/local/bin/node
COPY --from=node-builder /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node-builder /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=node-builder /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/lib/cli.js /usr/local/lib/cli.js

# Set up PHP sessions and logging directories
RUN set -eux; \
    mkdir -p /var/lib/php/sessions \
    && chown www-data:www-data -R /var/lib/php/sessions \
    && mkdir -p /var/log/php \
    && touch /var/log/php/php_errors.log \
    && chown -R www-data:www-data /var/log/php \
    && chmod -R 0777 /var/www

# Switch to www-data user for Shopware setup
USER www-data

# Set up Shopware project
RUN set -eux; \
    composer create-project shopware/production=${SW6VERSION} /var/www/freshware \
    && rm -rf /var/www/html \
    && ln -s /var/www/freshware /var/www/html \
    && cd /var/www/html \
    && composer update -n

# Switch back to root for final configurations
USER root

COPY config/packages/freshware.yaml /var/www/freshware/config/packages/freshware.yaml

RUN mkdir -p /etc/freshware/templates/php/

# Set permissions and create additional directory
RUN set -eux; \
    chown -R 33:33 /var/www /var/log \
    && mkdir -p /freshware \
    && chown -R 33:33 /freshware /etc/freshware /usr/local/etc/php/conf.d /usr/local/etc/php-fpm.d

# Copy and configure entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Final user and working directory setup
USER www-data

WORKDIR /var/www/freshware
EXPOSE 9000
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["php-fpm"]
