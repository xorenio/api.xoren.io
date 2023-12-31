FROM redis:bullseye

# Build arguments.
ARG APP_TIMEZONE=Europe/London
ARG APP_ENCODE=en_GB
ARG LCFILE=/etc/default/locale
ARG LGFILE=/etc/locale.gen

# Environment variables.
ENV DEBIAN_FRONTEND noninteractive
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

# For security settings uncomment, make the dir, copy conf, and also start with the conf, to use it
# RUN mkdir -p /usr/local/etc/redis
# COPY redis.conf /usr/local/etc/redis/redis.conf

# https://askubuntu.com/questions/1225410/my-ubuntu-server-has-been-infected-by-a-virus-kdevtmpfsi
# RUN touch /tmp/kdevtmpfsi && chmod 000 /tmp/kdevtmpfsi && touch /tmp/zzz && chmod 000 /tmp/zzz \
# JOKEs RIGHT HERE => https://github.com/docker-library/redis/issues/217#issuecomment-773349799
RUN echo "ALL_GOOD_HERE" > /tmp/kdevtmpfsi && chmod 000 /tmp/kdevtmpfsi \
    && echo "ALL_GOOD_HERE" > /tmp/kdevtmpfsi252738205 && chmod 000 /tmp/kdevtmpfsi252738205 \
    && echo "ALL_GOOD_HERE" > /var/tmp/kinsing && chmod 000 /var/tmp/kinsing \
    && echo "ALL_GOOD_HERE" > /tmp/zzz && chmod 000 /tmp/zzz \
    && echo "ALL_GOOD_HERE" > /tmp/zzz.sh && chmod 000 /tmp/zzz.sh \
    && chmod -R go-x /tmp \
    && chmod -R 0777 /tmp/ \
    && chmod -R go-x /var/tmp \
    && chmod -R 0777 /var/tmp/

# Remove packages no longer needed to reduce container size
RUN apt-get autoremove -y && apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

# Reset Environment variables.
ENV DEBIAN_FRONTEND dialog

VOLUME /data

EXPOSE 6379

CMD ["redis-server"]