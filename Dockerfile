FROM php:7.2-fpm

MAINTAINER jack "958691165@qq.com"

RUN mkdir -p /data

#时区设置
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone

ADD php.ini /usr/local/etc/php/
ADD php-fpm.conf /usr/local/etc/
ADD php-fpm.d/www.conf /usr/local/etc/php-fpm.d/
RUN pear config-set php_ini /usr/local/etc/php/php.ini
RUN pecl config-set php_ini /usr/local/etc/php/php.ini

#php-redis
RUN echo "\n\n" | pecl install -f redis

RUN docker-php-ext-enable redis

#php-gd
RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev
RUN docker-php-ext-install -j$(nproc) gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) iconv
RUN docker-php-ext-install -j$(nproc) exif

#php-pdo-mysql
RUN docker-php-ext-install -j$(nproc) pdo_mysql
#php-mysql
RUN docker-php-ext-install -j$(nproc) mysqli
#php-bcmath
RUN docker-php-ext-install -j$(nproc) bcmath
#php-opcache
RUN docker-php-ext-install -j$(nproc) opcache

RUN apt install -y zip libzip-dev && docker-php-ext-install -j$(nproc) zip

RUN mkdir -p /var/log/php

RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data
RUN groupmod -g 999 www-data
