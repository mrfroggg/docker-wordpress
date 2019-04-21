FROM wordpress:php7.3-apache
MAINTAINER cedric.charest@gmail.com

# enable extra Apache modules
RUN a2enmod rewrite expires headers

RUN apt-get update \
  && apt-get install -y zip exif git zip zlib1g-dev libpng-dev libjpeg-dev libxml2-dev libxslt-dev libgraphicsmagick1-dev graphicsmagick  mcrypt libmcrypt-dev libltdl7 gnupg libzip-dev

# install APCu from PECL
RUN pecl -vvv install apcu && docker-php-ext-enable apcu

# install GMagick from PECL
RUN pecl -vvv install gmagick-beta && docker-php-ext-enable gmagick

# install mcrypt
RUN pecl -vvv install mcrypt-1.0.2 && docker-php-ext-enable mcrypt

# install the PHP extensions we need
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-install gd json mysqli pdo pdo_mysql opcache gettext exif calendar soap sockets wddx zip

# Download WordPress CLI
RUN curl -L "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" > /usr/bin/wp \
    && chmod +x /usr/bin/wp

# Download Composer CLI
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && chmod +x /usr/bin/composer


# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# increase upload size
# see http://php.net/manual/en/ini.core.php
RUN { \
    echo "upload_max_filesize = 1024M"; \
    echo "post_max_size = 512M"; \
  } > /usr/local/etc/php/conf.d/uploads.ini

# Iron the security of the Docker
RUN { \
    echo "expose_php = Off"; \
    echo "display_startup_errors = off"; \
    echo "display_errors = off"; \
    echo "html_errors = off"; \
    echo "log_errors = on"; \
    echo "error_log = /dev/stderr"; \
    echo "ignore_repeated_errors = off"; \
    echo "ignore_repeated_source = off"; \
    echo "report_memleaks = on"; \
    echo "track_errors = on"; \
    echo "docref_root = 0"; \
    echo "docref_ext = 0"; \
    echo "error_reporting = -1"; \
    echo "log_errors_max_len = 0"; \
  } > /usr/local/etc/php/conf.d/security.ini


RUN { \
    echo "ServerSignature Off"; \
    echo "ServerTokens Prod"; \
    echo "TraceEnable off"; \
  } >> /etc/apache2/apache2.conf

RUN apt-get purge -y --auto-remove libpng-dev libjpeg-dev libxml2-dev libxslt-dev libgraphicsmagick1-dev libldap2-dev libmcrypt-dev

VOLUME /var/www/html
