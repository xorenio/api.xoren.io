#!/bin/bash

block_bots=${NGINX_BLOCK_BOTS:-"0"}
block_scanners=${NGINX_BLOCK_SCANNERS:-"0"}

# Function to check if the openssl commands have finished
check_openssl_commands() {
    while kill -0 "$1" 2>/dev/null; do
        sleep 1
    done
}

# Create Diffie-Hellman key exchange file if missing
if [[ ! -f "/etc/nginx/dhparam.pem" ]]; then
    echo "Creating dhparam"
    # Generate Diffie-Hellman parameters
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &
    # Capture the PID of the openssl command
    dhparam_pid=$!
fi

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

mkdir -p /etc/nginx/snippets
mkdir -p /etc/nginx/snippets/locations

user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$(( RANDOM % (115 - 91 + 1) + 91 )).0.$(( RANDOM % (2000 - 1 + 1) + 1 )).$(( RANDOM % (200 - 1 + 1) + 1 )) Safari/537.36"

nginx_snippet=/etc/nginx/snippets/block_bots.conf
if [[ ! -f "$nginx_snippet" ]]; then
    if [[ "${block_bots}" =  "1" ]]; then
        wget -q -O "$nginx_snippet" --user-agent="$user_agent" --no-check-certificate https://mirror.knthost.com/community/nginx/blocked_bots.conf
    fi

    if [[ ! -f "$nginx_snippet" ]]; then
        echo "" > "$nginx_snippet"
    fi
    chmod 777 "$nginx_snippet"
fi

nginx_snippet=/etc/nginx/snippets/block_scanners.conf
if [[ ! -f "$nginx_snippet" ]]; then
    if [[ "${block_scanners}" =  "1" ]]; then
        wget -q -O "$nginx_snippet" --user-agent="$user_agent" --no-check-certificate https://mirror.knthost.com/community/nginx/scanners.conf
    fi
    if [[ ! -f "$nginx_snippet" ]]; then
        echo "" > "$nginx_snippet"
    fi
    chmod 777 "$nginx_snippet"
fi

# Check if openssl commands have finished
if [[ -n $openssl_pid ]]; then
    check_openssl_commands "$openssl_pid"
fi
if [[ -n $dhparam_pid ]]; then
    check_openssl_commands "$dhparam_pid"
fi

config_file="/etc/nginx/conf.d/api.conf"

current_port=$(grep -Po "server laravel:\K\d+" "$config_file")

if [[ "$current_port" != "${SWOOLE_PORT:-8000}" ]]; then
    sed -i "s/server laravel:$current_port/server laravel:${SWOOLE_PORT:-8000}/g" "$config_file"
    sed -i "s/server localhost:$current_port backup/server localhost:${SWOOLE_PORT:-8000} backup/g" "$config_file"
fi

# Check if port ${SWOOLE_PORT:-8000} is open on laravel DNS using netcat, Kubernetes friendly
while ! nc -z -w1 laravel ${SWOOLE_PORT:-8000} && ! nc -z -w1 localhost ${SWOOLE_PORT:-8000}; do
    echo "[ERROR] http://laravel:${SWOOLE_PORT:-8000} is CLOSED."
    sleep 3s
done

echo "[SUCCESS] http://laravel:${SWOOLE_PORT:-8000} is OPEN."

# Start crond in the background
crond -l 2 -b

# Start nginx in the foreground
nginx