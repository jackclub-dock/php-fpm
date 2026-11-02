FROM laradock/php-fpm:latest-8.0

MAINTAINER jack "958691165@qq.com"

USER root

# Apply the official PHP 8.0 minimal security backport for php2shell
# (CVE-2026-109618, CVE-2026-109619; php-src commit 82f8f31b16a035c1b67cc253e79f7cc288f4cc20).
COPY php-8.0-php2shell-minimal.patch /tmp/php-8.0-php2shell-minimal.patch
RUN set -eux; \
    docker-php-source extract; \
    cd /usr/src/php; \
    patch -p1 -i /tmp/php-8.0-php2shell-minimal.patch; \
    ./configure \
        --build=x86_64-linux-gnu \
        --with-config-file-path=/usr/local/etc/php \
        --with-config-file-scan-dir=/usr/local/etc/php/conf.d \
        --enable-option-checking=fatal \
        --with-mhash \
        --with-pic \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
        --with-sqlite3=/usr \
        --with-curl \
        --with-iconv \
        --with-openssl \
        --with-readline \
        --with-zlib \
        --disable-phpdbg \
        --with-pear \
        --with-libdir=lib/x86_64-linux-gnu \
        --disable-cgi \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data; \
    make -j"$(nproc)"; \
    make install; \
    docker-php-source delete; \
    rm -rf /tmp/php*

#时区设置
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone

ADD php.ini /usr/local/etc/php/
RUN pear config-set php_ini /usr/local/etc/php/php.ini
RUN pecl config-set php_ini /usr/local/etc/php/php.ini

# Install Php Redis Extension
RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
  pecl install -o -f redis-4.3.0; \
else \
  pecl install -o -f redis; \
fi \
&& rm -rf /tmp/pear \
&& docker-php-ext-enable redis

#php-opcache
RUN docker-php-ext-install pcntl
#php-mysql
RUN  docker-php-ext-install mysqli
#php-bcmath
RUN docker-php-ext-install bcmath
#php-opcache
RUN docker-php-ext-install opcache
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

RUN apt update && apt install -y zip libzip-dev && docker-php-ext-install -j$(nproc) zip

#php-imagick
RUN apt-get install -y libmagickwand-dev; \
    pecl install imagick; \
    docker-php-ext-enable imagick;

RUN mkdir -p /var/log/php

RUN groupmod -o -g 1000 www-data && \
    usermod -o -u 1000 -g www-data www-data

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -f /var/log/lastlog /var/log/faillog

# Configure locale.
ARG LOCALE=POSIX
ENV LC_ALL ${LOCALE}

WORKDIR /var/www

CMD ["php-fpm"]

EXPOSE 9000
