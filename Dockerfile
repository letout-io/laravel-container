FROM php:8.0-apache

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils

# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        default-libmysqlclient-dev \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
        libonig-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libyaml-dev \
        libcurl4-gnutls-dev \
        libcap2-bin \
        libmemcachedutil2 \
    " \
    runtimeDeps=" \
        curl \
        jq \
        ca-certificates \
        ssh-client \
        zip \
        unzip \
        git \
        supervisor \
        cron \
    " \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $buildDeps $runtimeDeps \
    && docker-php-ext-install bcmath bz2 calendar intl mbstring mysqli tokenizer xml zip opcache pdo pdo_mysql pdo_pgsql pgsql soap pcntl \
    && docker-php-ext-configure gd --prefix=/usr --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-install exif \
    && pecl install memcached redis yaml \
    && docker-php-ext-enable memcached redis yaml \
    && apt-get purge -y --auto-remove \
    && rm -r /var/lib/apt/lists/* \
    && a2enmod rewrite remoteip headers expires setenvif 

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN echo 'memory_limit = 512M' > $PHP_INI_DIR/conf.d/memory_limit.ini

ADD supervisord.conf /etc/supervisor/
