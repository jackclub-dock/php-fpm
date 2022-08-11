FROM laradock/php-fpm:latest-8.0

MAINTAINER jack "958691165@qq.com"

USER root

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

# Install Php Xdebug Extension
RUN pecl install xdebug-beta
RUN docker-php-ext-enable redis xdebug
ADD xdebug.ini /usr/local/etc/php/conf.d/

#php-mysql
RUN docker-php-ext-install mysqli
#php-bcmath
RUN docker-php-ext-install bcmath
#php-opcache
RUN docker-php-ext-install opcache
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini
#php-imagick
ARG INSTALL_IMAGEMAGICK=true
ARG IMAGEMAGICK_VERSION=latest

RUN \
    if [ ${INSTALL_IMAGEMAGICK} = true ]; then \
      apt-get install -yqq libmagickwand-dev imagemagick && \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
        cd /tmp && \
        if [ ${IMAGEMAGICK_VERSION} = "latest" ]; then \
          git clone https://github.com/Imagick/imagick; \
        else \
          git clone --branch ${IMAGEMAGICK_VERSION} https://github.com/Imagick/imagick; \
        fi && \
        cd imagick && \
        phpize && \
        ./configure && \
        make && \
        make install && \
        rm -r /tmp/imagick; \
      else \
        pecl install imagick; \
      fi && \
      docker-php-ext-enable imagick; \
      php -m | grep -q 'imagick' \
    ;fi

RUN apt update && apt install -y zip libzip-dev && docker-php-ext-install -j$(nproc) zip

RUN mkdir -p /var/log/php

RUN groupmod -o -g 1000 www-data && \
    usermod -o -u 1000 -g www-data www-data

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Configure locale.
ARG LOCALE=POSIX
ENV LC_ALL ${LOCALE}

WORKDIR /var/www

CMD ["php-fpm"]

EXPOSE 9000

