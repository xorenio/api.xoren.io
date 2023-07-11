#!/bin/bash

# Function: __move_laravel_app_storage_folder
# Description: Private function to move the storage folder for Laravel.
# Parameters: None
# Returns: None

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

# Function: _pre_update
# Description: Performs pre update checks.
# Parameters: None
# Returns: None

_pre_update() {
    ## Enter project repo

    if [[ "$DOCKER_IS_PRESENT" = "1" ]]; then

        cd "$HOME/$GITHUB_REPO_NAME"

        DOCKER_FILE="$HOME/${GITHUB_REPO_NAME}/docker-compose.yml"
        if [[ -f "$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
            DOCKER_FILE="$HOME/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml"
        fi

        ## Stop running deployment
        _log_info "Stopping docker containers"
        docker-compose -f "${DOCKER_FILE}" down

        ## Remove deployment docker images
        _log_info "Removing docker images"
        yes | docker-compose -f "${DOCKER_FILE}" rm

        ## REMOVE DOCKER IMAGES VIA NAME
        if [[ "$YQ_IS_PRESENT" = "1" ]]; then
            yq '.services[].container_name' "${DOCKER_FILE}" |
            while IFS= read -r container_name; do
                yes | docker image rm "${container_name//\"}"
            done
        fi
    fi
}

# Function: _post_update
# Description: Performs some post flight checks..
# Parameters: None
# Returns: None

_post_update() {
    ## MOVE PROJECT FILES
    __move_laravel_app_storage_folder

    sync


    cp "$HOME/${GITHUB_REPO_NAME}/.env" "$HOME/${GITHUB_REPO_NAME}/laravel/.env"
    chmod 770 "$HOME/${GITHUB_REPO_NAME}/laravel/.env"

    _log_info "Finished updated project files."

    if [[ "$DOCKER_IS_PRESENT" = "1" ]]; then

        cd "$HOME/${GITHUB_REPO_NAME}" || return

        docker-compose -f "${DOCKER_FILE}" up -d --build

        ## CHANGE FILES AROUND 2FOR INSTALLING
        _log_info "Change files around for installing"
        # docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R
        docker-compose -f docker-compose.yml run --user root --rm laravel chown "$APP_USER" /var/www/ -R
        docker-compose -f "${DOCKER_FILE}" run --user root --rm laravel chown "$APP_USER" /var/www/ -R

        ## RESTART THE CONTAINER
        _log_info "Restart the containers"
        docker-compose -f "${DOCKER_FILE}" down
    fi

    ## RESET APP LOG FILES
    _log_info "Added deployment date to laravel logs"

    if [[ -d "$HOME"/"${GITHUB_REPO_NAME}"/laravel ]]; then
        for file in "$HOME"/"${GITHUB_REPO_NAME}"/laravel/storage/logs/*.log; do
            { \
                echo ""; \
                echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}"; \
                echo ""; \
            } >> "$file"
            chmod 777 "$file";
        done
        for file in "$HOME"/"${GITHUB_REPO_NAME}"/laravel/storage/logs/supervisord/*.log; do
            { \
                echo ""; \
                echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}"; \
                echo ""; \
            } >> "$file"
            chmod 777 "$file";
        done
    fi
    ## WAIT FOR FILE & FOLDER OPERATIONS TO COMPLETE
    if [[ "$SCREEN_IS_PRESENT" = "1" ]]; then
       while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_moving_storage"; do
           sleep 1s
       done
    fi

    if [[ "$DOCKER_IS_PRESENT" = "1" ]]; then
        cd "$HOME/${GITHUB_REPO_NAME}" || return
        docker-compose -f "${DOCKER_FILE}" up -d
    fi

    _delete_old_project_files
}