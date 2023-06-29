#!/bin/bash

role=${CONTAINER_ROLE:-laravel}
deployment=${APP_ENV:-local}

# Function to install vendor packages via composer
installPackages() {
  if [[ ! -d "vendor" ]]; then
    touch packages.installing.txt
    echo "[INFO] Installing PHP packages via composer"
    if [[ $deployment = "production" ]]; then
      composer install --prefer-dist --no-progress  --no-dev
      composer update
      npm install --production
    else
      composer install
      composer update
      npm install
    fi
    rm packages.installing.txt
  fi
}

# Wait for Laravel to boot
waitForLaravelBoot() {
  # Check if port ${SWOOLE_PORT:-8000} is open on laravel DNS using netcat
  while ! nc -z -w1 laravel ${SWOOLE_PORT:-8000}; do
      echo "[ERROR] http://laravel:${SWOOLE_PORT:-8000} is CLOSED."
      sleep 3s
  done

  echo "[SUCCESS] http://laravel:${SWOOLE_PORT:-8000} is OPEN."
}

# Wait for composer installation to finish
waitForPackages() {
  while [[ -f "packages.installing.txt" ]]; do
    sleep 1s
  done
}

# Production mode
if [[ $deployment != "local" ]]; then
  installPackages
  SUPERVISORD_CONF=/var/www/supervisord/production.conf
  SWOOLE_CMD="/usr/local/bin/php -d variables_order=EGPCS /var/www/artisan octane:start --server=swoole --host=0.0.0.0"
  SWOOLE_CMD="${SWOOLE_CMD} --port=${SWOOLE_PORT:-8000}"
  SWOOLE_CMD="${SWOOLE_CMD} --workers=${SWOOLE_WORKERS:-auto}"
  SWOOLE_CMD="${SWOOLE_CMD} --task-workers=${SWOOLE_TASK_WORKERS:-auto}"
  SWOOLE_CMD="${SWOOLE_CMD} --max-requests=${SWOOLE_MAX_REQUESTS:-500}"

  TRUES=(true 'true' "true" "True" "TRUE")

  for val in "${TRUES[@]}"; do
    if [[ "${SWOOLE_WATCH:-false}" == "$val" ]]; then
      SWOOLE_CMD=${SWOOLE_CMD}" --watch"
      break
    fi
  done

  sed -i '/\[program:laravel\]/,/\[/{/^command =/s#\(^command = \).*#\1'"$SWOOLE_CMD"'#}' "$SUPERVISORD_CONF"

  sed -i 's/\(user\s*=\s*\).*$/\1'"$APP_USER"'/' "$SUPERVISORD_CONF"
  sed -i 's/\(chown\s*=\s*\).*$/\1'"$APP_USER:$APP_USER"'/' "$SUPERVISORD_CONF"

  /usr/bin/supervisord -u "$APP_USER" -n -c "$SUPERVISORD_CONF"
  /usr/bin/supervisorctl start all

  exit
fi

# Script main runtime
case "$role" in
  "laravel")
    installPackages

    if [[ $SWOOLE_WATCH == "false" ]]; then
      /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan octane:start \
      --server=swoole \
      --host=0.0.0.0 \
      --port=${SWOOLE_PORT:-8000} \
      --workers=${SWOOLE_WORKERS:-auto} \
      --task-workers=${SWOOLE_TASK_WORKERS:-auto} \
      --max-requests=${SWOOLE_MAX_REQUESTS:-500}
    else
      /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan octane:start \
      --server=swoole \
      --host=0.0.0.0 \
      --port=${SWOOLE_PORT:-8000} \
      --workers=${SWOOLE_WORKERS:-auto} \
      --task-workers=${SWOOLE_TASK_WORKERS:-auto} \
      --max-requests=${SWOOLE_MAX_REQUESTS:-500} \
      --watch
    fi
    ;;
  *)
    waitForLaravelBoot
    waitForPackages
    case "$role" in
      "queue")
        /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan queue:listen --sleep=3 --tries=3 --queue=default --timeout=300 --memory=1280
        ;;
      "queue_high")
        /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan queue:listen --sleep=3 --tries=3 --queue=high --timeout=300 --memory=1280
        ;;
      "schedule")
        echo "" >> /var/www/storage/logs/schedule.txt

        while true; do
          /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan schedule:run --verbose --no-interaction --quiet >> /var/www/storage/logs/schedule.log 2>&1
          sleep 1s
        done
        ;;
      *)
        return
        ;;
    esac
    ;;
esac
