ARG MYSQL_VERSION
FROM mysql:${MYSQL_VERSION:-8}-debian

# Build arguments.
ARG APP_ENV=production
ARG APP_TIMEZONE="Europe/London"
ARG APP_ENCODE="en_GB"
ARG LCFILE="/etc/default/locale"
ARG LGFILE="/etc/locale.gen"

# Environment variables.
ENV DEBIAN_FRONTEND noninteractive
ENV APP_ENV ${APP_ENV}
ENV APP_USER ${APP_USER}
ENV APP_USER_UUID ${APP_USER_UUID}

# Set timezone and localization.
ENV TZ ${APP_TIMEZONE}
ENV LANG ${APP_ENCODE}.UTF-8
ENV LANGUAGE ${APP_ENCODE}.UTF-8
ENV LC_ALL ${APP_ENCODE}.UTF-8

# Update and upgrade system packages, then install required system packages.
RUN apt-get update && apt-get install -y -q \
apt-utils dialog locales tzdata ca-certificates

# Set timezone and localization.
RUN ln -snf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime && \
    echo "$APP_TIMEZONE" > /etc/timezone && \
    echo "en_US.UTF-8 UTF-8" > $LGFILE && \
    echo ${APP_ENCODE}".UTF-8 UTF-8" >> $LGFILE && \
    echo "LANG="${APP_ENCODE}".UTF-8" > $LCFILE && \
    for lc_var in ADDRESS IDENTIFICATION MEASUREMENT MONETARY NAME NUMERIC PAPER TELEPHONE TIME; \
    do echo "LC_${lc_var}=${APP_ENCODE}.UTF-8" >> $LCFILE; done && \
    dpkg-reconfigure --frontend noninteractive tzdata && locale-gen ${APP_ENCODE}.UTF-8 && update-locale

RUN chown -R mysql:root /var/lib/mysql/

# Remove packages no longer needed to reduce container size
RUN apt-get autoremove -y && apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND dialog

COPY $APP_ENV.cnf /etc/mysql/conf.d/custom.cnf

EXPOSE 3306

CMD ["mysqld"]