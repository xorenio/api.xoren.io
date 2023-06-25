#!/bin/bash

# Function to check if the openssl commands have finished
check_openssl_commands() {
    while kill -0 "$1" 2>/dev/null; do
        sleep 1
    done
}

# Create snakeoil cert if missing
if [[ ! -f "/etc/ssl/private/ssl-cert-snakeoil.key" || ! -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ]]; then
    echo "Creating snakeoil"
    # Generate a self-signed SSL certificate
    openssl req -x509 -nodes -newkey rsa:4096 \
        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
        -out /etc/ssl/certs/ssl-cert-snakeoil.pem -days 3650 \
        -subj "/C=${APP_ENCODE: -2}/ST=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/L=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/O=CompanyName/OU=IT Department/CN=example.com" &
    # Capture the PID of the openssl command
    openssl_pid=$!
fi

# Create Diffie-Hellman key exchange file if missing
if [[ ! -f "/etc/nginx/dhparam.pem" ]]; then
    echo "Creating dhparam"
    # Generate Diffie-Hellman parameters
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &
    # Capture the PID of the openssl command
    dhparam_pid=$!
fi

# Check if openssl commands have finished
if [[ -n $openssl_pid ]]; then
    check_openssl_commands "$openssl_pid"
fi
if [[ -n $dhparam_pid ]]; then
    check_openssl_commands "$dhparam_pid"
fi

# Check if port 9000 is open on laravel DNS using netcat
if nc -z -w1 laravel ${SWOOLE_PORT}; then
    echo "Port ${SWOOLE_PORT} is open on laravel"
else
    echo "Port ${SWOOLE_PORT} is not open on laravel"
    exit 1
fi

# Start crond in the background
crond -l 2 -b

# Start nginx in the foreground
nginx