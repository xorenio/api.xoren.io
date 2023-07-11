FROM nginx:alpine

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

ENV NGINX_BLOCK_BOTS ${NGINX_BLOCK_BOTS:-0}
ENV NGINX_BLOCK_SCANNERS ${NGINX_BLOCK_SCANNERS:-0}

# Set timezone and localization.
RUN rm -rf /etc/localtime && \
    ln -snf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime && \
    echo "en_US.UTF-8 UTF-8" > $LGFILE && \
    echo ${APP_ENCODE}".UTF-8 UTF-8" >> $LGFILE

RUN  rm -R /etc/nginx/conf.d && mkdir -p /etc/nginx/snippets/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/snippets/*.conf /etc/nginx/snippets/
COPY nginx/conf.d /etc/nginx/conf.d

# Update and upgrade system packages, then install required system packages.
RUN apk update \
    && apk upgrade \
    && apk --update add logrotate \
    && apk add --no-cache openssl \
    && apk add --no-cache bash \
    && apk add --no-cache --update musl musl-utils musl-locales tzdata \
    && apk add --no-cache ca-certificates \
    && apk add --no-cache curl wget

# Set timezone and localization.
RUN echo "export LC_ALL=${LANG}" >> /etc/profile.d/locale.sh && \
    sed -i 's|LANG=C.UTF-8|LANG='$LANG'|' /etc/profile.d/locale.sh
# && \
# openssl req -x509 -nodes -newkey rsa:4096 \
# -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
# -out /etc/ssl/certs/ssl-cert-snakeoil.pem -days 3650 \
# -subj "/C=${APP_ENCODE: -2}/ST=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/L=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/O=CompanyName/OU=IT Department/CN=example.com" && \
# openssl dhparam -out /etc/nginx/dhparam.pem 2048

# Create system user
RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

# Create 'messages' file used from 'logrotate'
RUN touch /var/log/messages

# Copy 'logrotate' config file
COPY nginx/logrotate/nginx /etc/logrotate.d/
COPY --chown=www-data:www-data laravel/ /var/www

COPY nginx/docker.sh /opt/docker.sh

# removes windows line ending
RUN sed -i 's/\r//g' /opt/docker.sh

# Remove packages no longer needed to reduce container size
RUN rm -rf /var/lib/apt/lists/*

# Reset Environment variables.
ENV DEBIAN_FRONTEND dialog

EXPOSE 80 81 443

CMD ["/bin/bash", "/opt/docker.sh"]