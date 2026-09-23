FROM alpine:3.23

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    php83-json \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-simplexml \
    php83-zip \
    php83-zlib \
    php83-gd \
    php83-intl \
    php83-opcache \
    php83-phar \
    php83-session \
    php83-tokenizer \
    php83-iconv \
    php83-posix \
    mariadb-client \
    curl \
    bash \
    && ln -sf /usr/bin/php83 /usr/bin/php

# Install WP-CLI
RUN curl -sSL -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN sed -i 's/^listen = .*/listen = 9000/' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's/;listen.owner/listen.owner/' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's/;listen.group/listen.group/' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's/;clear_env = no/clear_env = no/' /etc/php83/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY wp-entrypoint.sh /usr/local/bin/wp-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["wp-entrypoint.sh"]
