FROM php:8.2-apache

ENV NODE_MAJOR=20
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils curl gnupg \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update

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
        gnupg \
        wget \
        jq \
        ca-certificates \
        ssh-client \
        zip \
        unzip \
        git \
        supervisor \
        cron \
        nodejs \
    " \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $buildDeps $runtimeDeps \
    && docker-php-ext-install bcmath bz2 calendar intl mbstring mysqli xml zip opcache pdo pdo_mysql pdo_pgsql pgsql soap pcntl sockets \
    && docker-php-ext-configure gd --prefix=/usr --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-install exif \
    && pecl install memcached redis yaml \
    && pecl install --configureoptions 'enable-openssl="yes" enable-sockets="yes" enable-mysqlnd="yes" enable-swoole-curl="yes" ' swoole \
    && docker-php-ext-enable memcached redis yaml swoole \
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
