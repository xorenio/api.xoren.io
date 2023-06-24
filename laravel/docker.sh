#!/bin/bash

role=${CONTAINER_ROLE:-laravel}
deployment=${APP_ENV:-local}


# install vendor packages
# via composer
installVendorPackages() {
  if [[ ! -d "vendor" ]]; then
      # Place file to cause wait on other processes
      touch composer.install.txt
      echo "[INFO] Installing Php Packages via composer"
      composer install
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

  sed -i 's/\(user\s*=\s*\).*$/\1'$APP_USER'/' /var/www/supervisord/production.conf
  sed -i 's/\(chown\s*=\s*\).*$/\1'$APP_USER':'$APP_USER'/' /var/www/supervisord/production.conf
  /usr/bin/supervisord -u ${APP_USER} -n -c /var/www/supervisord/production.conf
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
    php artisan octane:start --server=swoole --host=0.0.0.0 --port=${SWOOLE_PORT:-8000} --workers=${SWOOLE_WORKERS:-auto} --task-workers=${SWOOLE_TASK_WORKERS:-auto} --max-requests=${SWOOLE_MAX_REQUESTS:-500} --watch
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
          php artisan schedule:run --verbose --no-interaction --quiet >> /var/www/storage/logs/schedule.txt 2>&1;
          sleep 1s
        done
        ;;

      *)
        return
        ;;
    esac
    ;;
esac