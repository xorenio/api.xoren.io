#!/bin/bash

#######################################################################
# Nginx and Laravel Startup Script
#######################################################################
#
# This script is designed to set up and run Nginx with Laravel,
# handling various configurations and checks based on environment
# variables and dependencies.
#
# Usage:
#   ./startup.sh
#
# Environment Variables:
#   - NGINX_BLOCK_BOTS: Enable or disable blocking known bots. Default is "0".
#   - NGINX_BLOCK_SCANNERS: Enable or disable blocking known scanners. Default is "0".
#   - PHP_PORT: Port on which the Laravel server should run. Default is "8000".
#
# Dependencies:
#   - Requires OpenSSL for generating Diffie-Hellman parameters and SSL certificate.
#   - Requires nc (netcat) for checking if Laravel is running.
#
#######################################################################

block_bots=${NGINX_BLOCK_BOTS:-"0"}
block_scanners=${NGINX_BLOCK_SCANNERS:-"0"}
swoole_port=${SWOOLE_PORT:-9000}

# Function: _check_openssl_commands
# Description: Check if the openssl commands have finished.
# Parameters: None
# Returns: None

_check_openssl_commands() {
    while kill -0 "$1" 2>/dev/null; do
        sleep 1
    done
}

# Function: _wait_for_laravel
# Description: Wait for Laravel to boot.
# Parameters: None
# Returns: None

_wait_for_laravel() {

    local check_count=0

    # Check if port ${php_port:-9000} is open on the Laravel DNS using netcat, Kubernetes friendly
    while ! nc -z -w1 laravel "$swoole_port" && ! nc -z -w1 localhost "$swoole_port"; do
        if [[ $check_count -eq 1 ]]; then
            echo "[ERROR] http://laravel:$swoole_port is CLOSED."
        elif [[ $check_count -ge 10 ]]; then
            echo "[ERROR] http://laravel:$swoole_port is CLOSED."
        fi
        check_count=$((check_count + 1))
        sleep 1s
    done

    echo "[SUCCESS] http://laravel:${swoole_port:-9000} is OPEN."
}

# Generate Diffie-Hellman key exchange file if missing.
if [[ ! -f "/etc/nginx/dhparam.pem" ]]; then
    echo "Creating dhparam"
    # Generate Diffie-Hellman parameters.
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 >/dev/null 2>&1 &
    # Capture the PID of the openssl command.
    dhparam_pid=$!
fi

# Generate snakeoil cert if missing.
if [[ ! -f "/etc/ssl/private/ssl-cert-snakeoil.key" || ! -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ]]; then
    echo "Creating snakeoil"
    # Generate a self-signed SSL certificate.
    openssl req -x509 -nodes -newkey rsa:4096 \
        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
        -out /etc/ssl/certs/ssl-cert-snakeoil.pem -days 3650 \
        -subj "/C=${APP_ENCODE: -2}/ST=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/L=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/O=CompanyName/OU=IT Department/CN=example.com" >/dev/null 2>&1 &
    # Capture the PID of the openssl command.
    openssl_pid=$!
fi

# Create necessary directories.
mkdir -p /etc/nginx/snippets
mkdir -p /etc/nginx/snippets/locations

user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$((RANDOM % (115 - 91 + 1) + 91)).0.$((RANDOM % (2000 - 1 + 1) + 1)).$((RANDOM % (200 - 1 + 1) + 1)) Safari/537.36"

# Configure blocking bots
nginx_snippet=/etc/nginx/snippets/block_bots.conf
nginx_url=https://mirror.knthost.com/community/nginx/blocked_bots.conf
if [[ ! -f "$nginx_snippet" ]]; then
    if [[ "${block_bots}" = "1" ]]; then
        if ! wget -q -O "${nginx_snippet}" --user-agent="${user_agent}" --no-check-certificate "${nginx_url}"; then
            cat >"${nginx_snippet}" <<EOF
map \$http_user_agent \$blocked_bots {
default 0;
"~Auto Spider 1.0" 1;
"~Babya Discoverer" 1;
"~Crawlera" 1;
"~Crowsnest/0.5" 1;
"~DataCha0s" 1;
"~DomainSONOCrawler/0.1" 1;
"~Dow Jones Searchbot" 1;
"~DownloadBot" 1;
"~heritrix" 1;
"~heritrix/3.1.1" 1;
"~JCE" 1;
"~Morfeus f scanner" 1;
"~Mozilla/0.6 Beta (Windows)" 1;
"~Mozilla-1.1" 1;
"~MSProxy/2.0" 1;
"~null" 1;
"~proxyjudge.info" 1;
"~proxyjudge" 1;
"~SecurityResearch.bot" 1;
"~SiteChecker/0.1" 1;
"~WBSearchBot/1.1" 1;
"~WebFuck" 1;
"~Windows Live Writer" 1;
"~WinHttp.WinHttpRequest.5" 1;
"~ZmEu" 1;
"~Zollard" 1;
}
EOF
        fi
    fi
    sync
    if [[ ! -f "$nginx_snippet" ]]; then
        cat >"${nginx_snippet}" <<EOF
map \$http_user_agent \$blocked_bots {
default 0;
}
EOF
    fi
    chmod 777 "$nginx_snippet"
fi

# Configure blocking scanners.
nginx_snippet=/etc/nginx/snippets/block_scanners.conf
nginx_url=https://mirror.knthost.com/community/nginx/scanners.conf
if [[ ! -f "$nginx_snippet" ]]; then
    if [[ "${block_scanners}" = "1" ]]; then
        if ! wget -q -O "${nginx_snippet}" --user-agent="${user_agent}" --no-check-certificate "${nginx_url}"; then
            cat >"${nginx_snippet}" <<EOF
map \$http_user_agent \$scanners {
default 0;
"~Comodo-Webinspector-Crawler" 1;
"~ErrataSecScanner" 1;
"~httpscheck" 1;
"~Load Impact" 1;
"~ltx71" 1;
"~masscan" 1;
"~mfibot/1.1" 1;
"~muhstik-scan" 1;
"~*nikto" 1;
"~Nmap Scripting Engine" 1;
"~Nmap" 1;
"~*NYU Internet Census (https://scan.lol; research@scan.lol)" 1;
"~*OpenVAS" 1;
"~project25499.com" 1;
"~proxytest.zmap.io" 1;
"~Researchscan/t12sns" 1;
"~Riddler" 1;
"~SafeSearch microdata crawler" 1;
"~ScanAlert" 1;
"~scan.nextcloud.com" 1;
"~Scanning for research" 1;
"~SiteLock" 1;
"~SiteLockSpider" 1;
"~sysscan" 1;
"~*sqlmap" 1;
"~zgrab/0.x" 1;
}
EOF
        fi
    fi
    sync
    if [[ ! -f "$nginx_snippet" ]]; then
        cat >"${nginx_snippet}" <<EOF
map \$http_user_agent \$scanners {
default 0;
}
EOF
    fi
    chmod 777 "$nginx_snippet"
fi

# Check if openssl commands have finished
if [[ -n $openssl_pid ]]; then
    _check_openssl_commands "$openssl_pid"
fi
if [[ -n $dhparam_pid ]]; then
    _check_openssl_commands "$dhparam_pid"
fi

# Update Laravel configuration if the port has changed.
config_file="/etc/nginx/conf.d/api.conf"
current_port=$(grep -o "server laravel:[0-9]*" "$config_file" | awk -F ':' '{print $2}')
# Registered ports (1024-49151): These ports are used by applications and services that are not considered well-known but still require standardized port assignments.
if [[ -n "$current_port" && "$current_port" -ge 1024 && "$current_port" -le 49151 ]]; then
    if [[ "$current_port" != "$swoole_port" ]]; then
        sed -i "s|server laravel:$current_port|server laravel:$swoole_port|g" "$config_file"
        sed -i "s|server localhost:$current_port backup|server localhost:$swoole_port backup|g" "$config_file"
    fi
fi
sync "$config_file"

# Wait for Laravel to boot.
_wait_for_laravel

# Start crond in the background.
crond -l 2 -b

# Start nginx in the foreground.
nginx
