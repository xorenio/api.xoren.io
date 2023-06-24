#!/bin/bash

# Create snakeoil cert if missing
# if [[ ! -f "/etc/ssl/private/ssl-cert-snakeoil.key" || ! -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ]]; then
#     echo "Creating snakeoil"
#     openssl req -x509 -nodes -newkey rsa:4096 \
#         -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
#         -out /etc/ssl/certs/ssl-cert-snakeoil.pem -days 3650 \
#         -subj "/C=${APP_ENCODE: -2}/ST=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/L=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/O=CompanyName/OU=IT Department/CN=example.com"
# fi

# Create Diffie-Hellman key exchange file if missing
if [[ ! -f "/etc/nginx/dhparam.pem" ]]; then
    echo "Creating dhparam"
    openssl dhparam -out /etc/nginx/dhparam.pem 2048
fi

# Check if port 9000 is open on laravel DNS using netcat
if nc -z -w1 laravel ${SWOOLE_PORT}; then
    echo "Port ${SWOOLE_PORT} is open on laravel"
else
    echo "Port ${SWOOLE_PORT} is not open on laravel"
    exit 1
fi

# Start crond in background
crond -l 2 -b

# Start nginx in foreground
nginx
