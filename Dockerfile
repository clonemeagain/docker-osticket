# Using the work of Martin Campbell <martin@campbellsoftware.co.uk> .. just modified a bit.
# Mainly getting it ready for 1.11, which supports PHP7 etc. 
# Also, adapting it for Apache, because that is the web-server
# osTicket supports. Nginx is great, however, for development..  Apache!

# TODO: Enable email

# 7.3-stretch-apache.. something comes with curl/zlib/etc..
FROM php:7-apache
MAINTAINER Aaron Were <clonemeagain@gmail.com>
ENV APACHE_DOCUMENT_ROOT=/data/upload

# Commented out parts:
# RUN docker-php-ext-configure imap --with-imap-ssl

# Gets the dev libraries, runs the docker-php extension build scripts enabling those special/required modules
# Then cleans up, sets the Timezone to UTC and then configures Apache a bit. 
# We are not trying to do everything here, just setup a webserver. Once we have one of those, we can use userland scripts
# to configure and setup osTicket if necessary. 
RUN apt-get update \
    && apt-get install -y git-core libc-client-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxml2 libxml2-dev \
    && docker-php-ext-install -j$(nproc) gd mysqli sockets gettext intl opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/localtime \
    && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
    && "date" \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && echo "ServerName osticket" >> /etc/apache2/apache2.conf

# Now that we have a web-server container that can run osTicket
# Let's setup the dev environment for osticket
COPY ./setup /setup
RUN chmod +x /setup/start.sh
ENTRYPOINT ["bash","-c","/setup/start.sh"]
# No ports are exposed, as we assume you are using the docker-compose file and port 8080