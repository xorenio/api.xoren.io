FROM php:8.2-fpm

# Build arguments.
ARG APP_ENV=local
ARG APP_USER=laravel
ARG APP_USER_UUID=1000
ARG APP_TIMEZONE=Europe/London
ARG APP_ENCODE=en_GB
ARG LCFILE=/etc/default/locale
ARG LGFILE=/etc/locale.gen
ARG NODE_VERSION=20
ARG SWOOLE_PORT=9000

# Environment variables.
ENV APP_ENV ${APP_ENV}
ENV APP_USER ${APP_USER}
ENV DEBIAN_FRONTEND noninteractive
ENV TZ ${APP_TIMEZONE}
ENV LANG ${APP_ENCODE}.UTF-8
ENV LANGUAGE ${APP_ENCODE}.UTF-8
ENV LC_ALL ${APP_ENCODE}.UTF-8

# Swoole Environment variables.
ENV SWOOLE_MAX_REQUESTS ${SWOOLE_MAX_REQUESTS:-500}
ENV SWOOLE_TASK_WORKERS ${SWOOLE_TASK_WORKERS:-auto}
ENV SWOOLE_WATCH ${SWOOLE_WATCH:-false}
ENV SWOOLE_WORKERS ${SWOOLE_WORKERS:-auto}
ENV SWOOLE_PORT ${SWOOLE_PORT:-9000}


# Update and upgrade system packages, then install required system packages.
RUN apt-get update && apt-get upgrade -y -q && \
    apt-get install -y -q apt-utils dialog locales tzdata \
    build-essential ca-certificates cmake curl default-mysql-client \
    gcc git glew-utils gosu htop iputils-ping libcap2-bin libfreetype6-dev \
    libgconf-2-4 libglew-dev libjpeg-dev libonig-dev libpng-dev \
    libx11-dev libxcursor-dev libxi6 libxinerama-dev libxml2-dev libxrandr-dev \
    libzip-dev nano nasm pngquant python3 python3-pip screen \
    software-properties-common sqlite3 sudo supervisor unzip wget zip imagemagick \
    autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c && \
    apt-get install -y -q --no-install-recommends mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Set timezone and localization.
RUN ln -snf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime && \
    echo "$APP_TIMEZONE" > /etc/timezone && \
    echo "en_US.UTF-8 UTF-8" > $LGFILE && \
    echo ${APP_ENCODE}".UTF-8 UTF-8" >> $LGFILE && \
    echo "LANG="${APP_ENCODE}".UTF-8" > $LCFILE && \
    for lc_var in ADDRESS IDENTIFICATION MEASUREMENT MONETARY NAME NUMERIC PAPER TELEPHONE TIME; \
    do echo "LC_${lc_var}=${APP_ENCODE}.UTF-8" >> $LCFILE; done && \
    dpkg-reconfigure --frontend noninteractive tzdata && locale-gen ${APP_ENCODE}.UTF-8 && update-locale

# Install PHP extensions.
RUN docker-php-ext-install pdo_mysql ctype exif pcntl bcmath && \
    pecl install redis zip swoole && \
    docker-php-ext-enable redis zip swoole

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Nodejs
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
RUN apt-get -y -q install nodejs procps && npm install -g chokidar

# Create system user
RUN useradd -ms /bin/bash -G users,www-data,sudo -u $APP_USER_UUID -d /home/$APP_USER $APP_USER && \
    mkdir -p /home/$APP_USER/.composer /var/www/vendor && \
    chown -R $APP_USER:$APP_USER /home/$APP_USER /var/www/vendor && \
    { \
        echo "root ALL=(ALL) ALL"; \
        echo "$APP_USER ALL=(ALL) NOPASSWD: ALL"; \
        echo "%sudo ALL=(ALL) ALL"; \
        echo "@includedir /etc/sudoers.d"; \
        echo "Defaults insults"; \
    } > /etc/sudoers

# Copy Laravel project
COPY laravel/ /var/www
RUN chown -R $APP_USER:$APP_USER /home/$APP_USER /var/www

# Copy Php config
COPY php/php-ini-overrides.ini /usr/local/etc/php/php.ini
COPY php/php-fpm.d/$APP_ENV/* /usr/local/etc/php-fpm.d/

# Remove packages no longer needed to reduce container size
RUN apt-get purge -y git \
    build-essential cmake software-properties-common && \
    apt-get autoremove -y && apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

# Reset Environment variables.
ENV DEBIAN_FRONTEND dialog

WORKDIR /var/www

USER $APP_USER

RUN npm install --save-dev chokidar

# Expose the ports that Octane is using.
EXPOSE $SWOOLE_PORT

CMD ["bash", "/var/www/docker.sh"]
