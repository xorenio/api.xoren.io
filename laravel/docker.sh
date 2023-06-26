#!/bin/bash

role=${CONTAINER_ROLE:-laravel}
deployment=${APP_ENV:-local}

# swoole_task_workers=${SWOOLE_WA:-auto}
# swoole_task_workers=${SWOOLE_TASK_WORKERS:-auto}
# swoole_port=${SWOOLE_PORT:-8000}
# swoole_workers=${SWOOLE_WORKERS:-auto}
# swoole_max_requests=${SWOOLE_MAX_REQUESTS:-500}



# install vendor packages
# via composer
installVendorPackages() {
  if [[ ! -d "vendor" ]]; then
      # Place file to cause wait on other processes
      touch composer.install.txt
      echo "[INFO] Installing Php Packages via composer"
      if [[ $deployment = "production" ]]; then
        composer install --no-dev
        composer update
        npm install --production
      else
        composer install
        composer update
        npm install
      fi
      rm composer.install.txt
  fi
}

# Function to add in wait
# for laravel startup
waitForLaravelBoot() {
    sleep 3s
}

# Function to add in wait
# for composer to  install
waitForComposer() {
    while [[ -f "composer.install.txt" ]]; do
        sleep 1s
    done
}

# Production mode
if [[ $deployment != "local" ]]; then
  installVendorPackages
  SUPERVISORD_CONF=/var/www/supervisord/production.conf
  SWOOLE_CMD="/usr/local/bin/php -d variables_order=EGPCS /var/www/artisan octane:start --server=swoole --host=0.0.0.0"
  SWOOLE_CMD=${SWOOLE_CMD}" --port="${SWOOLE_PORT:-8000}
  SWOOLE_CMD=${SWOOLE_CMD}" --workers="${SWOOLE_WORKERS:-auto}
  SWOOLE_CMD=${SWOOLE_CMD}" --task-workers="${SWOOLE_TASK_WORKERS:-auto}
  SWOOLE_CMD=${SWOOLE_CMD}" --max-requests="${SWOOLE_MAX_REQUESTS:-500}

  TRUES=(true 'true' "true" "True" "TRUE")

  for val in "${TRUES[@]}"; do
    if [[ "${SWOOLE_WATCH:-false}" == "$val" ]]; then
      echo "YES SWOOLE_WATCH: ${SWOOLE_WATCH:-false}"
      SWOOLE_CMD=${SWOOLE_CMD}" --watch"
      break
    fi
  done

  # this is the broken sed command its doesnt seem to change the command
  sed -i '/\[program:laravel\]/,/\[/{/^command =/s#\(^command = \).*#\1'"$SWOOLE_CMD"'#}' $SUPERVISORD_CONF

  # Replace the user
  sed -i 's/\(user\s*=\s*\).*$/\1'$APP_USER'/' $SUPERVISORD_CONF
  sed -i 's/\(chown\s*=\s*\).*$/\1'$APP_USER':'$APP_USER'/' $SUPERVISORD_CONF


  /usr/bin/supervisord -u ${APP_USER} -n -c ${SUPERVISORD_CONF}
  /usr/bin/supervisorctl start all

  exit;
fi

##
## Script main runtime
##
case "$role" in

  "laravel")
    installVendorPackages

    # Start Laravel
    # php-fpm
    if [[ $SWOOLE_WATCH == "false" ]]; then
        php artisan octane:start --server=swoole --host=0.0.0.0 \
        --port=${SWOOLE_PORT:-8000} --workers=${SWOOLE_WORKERS:-auto} \
        --task-workers=${SWOOLE_TASK_WORKERS:-auto} --max-requests=${SWOOLE_MAX_REQUESTS:-500}
    else
        php artisan octane:start --server=swoole --host=0.0.0.0 \
        --port=${SWOOLE_PORT:-8000} --workers=${SWOOLE_WORKERS:-auto} \
        --task-workers=${SWOOLE_TASK_WORKERS:-auto} --max-requests=${SWOOLE_MAX_REQUESTS:-500} --watch
    fi
    ;;
  *)
    waitForLaravelBoot
    waitForComposer
    case "$role" in

      "queue")
        /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan queue:listen --sleep=3 --tries=3 --queue=default --timeout=300 --memory=1280
        ;;

      "queue_high")
        /usr/local/bin/php -d variables_order=EGPCS /var/www/artisan queue:listen --sleep=3 --tries=3 --queue=high --timeout=300 --memory=1280
        ;;

      "schedule")
        echo "" >> /var/www/storage/logs/schedule.txt

        while :
        do
          php artisan schedule:run --verbose --no-interaction --quiet >> /var/www/storage/logs/schedule.log 2>&1;
          sleep 1s
        done
        ;;

      *)
        return
        ;;
    esac
    ;;
esac
