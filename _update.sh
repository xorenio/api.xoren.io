#!/bin/bash

__move_laravel_app_storage_folder() {
    _log_info "Moving laravel storage folder"

    ## IF SCREEN PROGRAM IS INSTALL
    if [[ "$SCREEN_IS_PRESENT" = "true" ]]; then

        ## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
        if ! screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_moving_storage"; then

            _log_info "Moving laravel/storage/app folder files moving task in background."


            ## Create screen
            screen -dmS "${GITHUB_REPO_NAME}_deployment_moving_storage"


            ## Pipe command to screen
            screen -S "${GITHUB_REPO_NAME}_deployment_moving_storage" -p 0 -X stuff 'rm '$HOME'/'${GITHUB_REPO_NAME}'/laravel/storage/ -R \n'
            screen -S "${GITHUB_REPO_NAME}_deployment_moving_storage" -p 0 -X stuff 'mv -u -f '$HOME'/'${GITHUB_REPO_NAME}'_'${NOWDATESTAMP}'/laravel/storage/ '$HOME'/'${GITHUB_REPO_NAME}'/laravel/ \n'


            ## Pipe in exit separately to ensure exit on screen
            screen -S "${GITHUB_REPO_NAME}_deployment_moving_storage" -p 0 -X stuff 'exit\n'

        else # IF SCREEN FOUND

            _log_error "Task of moving vendor folder in background already running."
        fi
    else ## IF NO SCREEN PROGRAM

        ## Moving files in this process
        _log_info ""
        _log_info "Running moving laravel/storage/app."
        rm "$HOME/${GITHUB_REPO_NAME}/laravel/storage/" -R
        mv -u -f "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}/laravel/storage/" "$HOME/${GITHUB_REPO_NAME}/laravel/"
        _log_info "Finished Moving laravel/storage/app folder."
        _log_info ""
    fi
}

_log_to_file ""
_log_to_file "Re-deployment Started"
_log_to_file "====================="
_log_to_file "env: ${DEPLOYMENT_ENV}"

## Enter project repo
cd "$HOME/$GITHUB_REPO_NAME"

## Stop running deployment
_log_info "Stopping docker containers"
if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
    docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml" down
else
    docker-compose down
fi

## Remove deployment docker images
_log_info "Removing docker images"
if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
    yes | docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml" rm #--all # dep
else
    yes | docker-compose rm #--all # dep
fi

## REMOVE DOCKER IMAGES VIA NAME
yes | docker image rm xoren-io-laravel
yes | docker image rm xoren-io-nginx
yes | docker image rm xoren-io-websocket

## LEAVE PROJECT DIRECTORY
cd "$HOME"

## RENAME OLD PROJECT DIRECTORY
_log_to_file "Moving old project folder."

[[ -f "$HOME"/"$GITHUB_REPO_NAME"/.env ]] && rm "$HOME"/"$GITHUB_REPO_NAME"/.env

mv -u -f "$HOME/$GITHUB_REPO_NAME" "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}"

## WAIT FOR INODE CHANGES
sync

## CLONE FRESH COPY OF PROJECT / no log file
git clone "git@github.com:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git"

## WAIT FOR INODE CHANGES
sync

_log_to_file "Finished cloning fresh copy from github $GITHUB_REPO_OWNER/${GITHUB_REPO_NAME}."

# _log_info "cd to updated local project files"
cd "$HOME/${GITHUB_REPO_NAME}"

## MOVE PROJECT FILES
__move_laravel_app_storage_folder

sync

_log_to_file "Finished cloning fresh copy from github $GITHUB_REPO_OWNER/${GITHUB_REPO_NAME}."

cd "$HOME/${GITHUB_REPO_NAME}"

## REPLACE ENV FILES
_log_to_file "Moving project secrets in to .env file."
_replace_env_project_secrets
cp "$HOME/${GITHUB_REPO_NAME}/.env" "$HOME/${GITHUB_REPO_NAME}/laravel/.env"

_log_info "Finished updated project files."
_log_to_file ""

if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
    docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml" up -d --build
else
    docker-compose up -d --build
fi

## CHANGE FILES AROUND 2FOR INSTALLING
_log_info "Change files around for installing"
# docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R
docker-compose -f docker-compose.yml run --user root --rm laravel chown "$APP_USER" /var/www/ -R

## INSTALL PHP DEPS
_log_info "Installing php deps"
if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
    docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml" run --rm laravel composer install --no-dev
    docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml "run --rm laravel composer update
else
    docker-compose run --rm laravel composer install --no-dev
    docker-compose run --rm laravel composer update
fi

## CHANGE FILE PERMS
# _log_info "Change file perms"
# docker-compose -f docker-compose.yml run --rm laravel php artisan queue:flush
# docker-compose -f docker-compose.yml run --rm laravel php artisan queue:clear
# docker-compose -f docker-compose.yml run --rm laravel php artisan cache:clear
# docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R
# docker-compose -f docker-compose.yml run --user root --rm laravel rm /var/www/package-lock.json
# docker-compose -f docker-compose.yml run --user root --rm laravel rm /laravel/public/mix-manifest.json

## INSTALL NPM PACKAGES
# _log_info "Install npm"
# docker-compose -f docker-compose.yml run --rm laravel npm install

## BUILD JS TO BUNDLE
# _log_info "Building javascript bundles"
# docker-compose -f docker-compose.yml run --rm laravel npm run testing

## RESTART THE CONTAINER
_log_info "Restart the containers"
if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
    docker-compose -f "docker-compose.${DEPLOYMENT_ENV}.yml" down
else
    docker-compose down
fi

## LAST FILE PERMS FIX
_log_info "Last file perms fix"
if [[ -f "$HOME"/"${GITHUB_REPO_NAME}"/docker-compose."${DEPLOYMENT_ENV}".yml ]]; then
    docker-compose -f docker-compose."${DEPLOYMENT_ENV}".yml run --user root --rm laravel chown "$APP_USER" /var/www/ -R
else
    docker-compose run --user root --rm laravel chown "${APP_USER}" /var/www/ -R
fi

## RESET APP LOG FILES
_log_info "Added deployment date to laravel logs"

for file in "$HOME"/"${GITHUB_REPO_NAME}"/laravel/storage/logs/*.log; do
    echo "" >> "$file";
    echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}" >> "$file";
    echo "" >> "$file";
    chmod 777 "$file";
done
for file in "$HOME"/"${GITHUB_REPO_NAME}"/laravel/storage/logs/supervisord/*.log; do
    echo "" >> "$file";
    echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}" >> "$file";
    echo "" >> "$file";
    chmod 777 "$file";
done
## WAIT FOR FILE & FOLDER OPERATIONS TO COMPLETE
if [[ "$SCREEN_IS_PRESENT" == "true" ]]; then
   while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_moving_storage"; do
       sleep 1s
   done
fi

if [[ -f "$HOME"/"${GITHUB_REPO_NAME}"/docker-compose."${DEPLOYMENT_ENV}".yml ]]; then
    docker-compose -f docker-compose."${DEPLOYMENT_ENV}".yml up -d
else
    docker-compose up -d
fi