#!/bin/bash

# START - IMPORT FUNCTIONS
if [[ ! -n "$(type -t _exit_script)" ]]; then
    source _functions.sh
fi
# END - IMPORT FUNCTIONS

# Function: __move_laravel_app_storage_folder
# Description: Private function to move the storage folder for Laravel.
# Parameters: None
# Returns:
#   The PID of the process for move.

__move_laravel_app_storage_folder() {
    local move_file_pid
    _log_info "Moving laravel storage folder"

    ## Moving files in this process
    _log_info ""
    _log_info "Running moving laravel/storage/app."
    rm "$HOME/${GIT_REPO_NAME}/laravel/storage/" -R
    rm -rf "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/laravel/vendor/" &
    mv -u -f "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/laravel/storage/" "$HOME/${GIT_REPO_NAME}/laravel/" &
    move_file_pid=$!

    _log_info "Finished Moving laravel/storage/app folder."
    _log_info ""
    echo ${move_file_pid}
}

# Function: _pre_update
# Description: Performs pre update checks.
# Parameters: None
# Returns: None

_pre_update() {
    local dhparam_pid=false
    local openssl_pid=false
    ## Enter project repo
    if [[ ! -d "$HOME/pems" ]]; then
        mkdir -p "$HOME/pems"
    fi
    # Create Diffie-Hellman key exchange file if missing
    if [[ ! -f "$HOME/pems/dhparam.pem" ]]; then
        _log_info "Creating dhparam"
        # Generate Diffie-Hellman parameters
        openssl dhparam -out "$HOME/pems/dhparam.pem" 2048 >/dev/null 2>&1 &
        # Capture the PID of the openssl command
        dhparam_pid=$!
    fi

    # Create snakeoil cert if missing
    if [[ ! -f "$HOME/pems/ssl-cert-snakeoil.key" || ! -f "$HOME/pems/ssl-cert-snakeoil.pem" ]]; then
        _log_info "Creating snakeoil"
        # Generate a self-signed SSL certificate
        openssl req -x509 -nodes -newkey rsa:4096 \
            -keyout "$HOME/pems/ssl-cert-snakeoil.key" \
            -out "$HOME/pems/ssl-cert-snakeoil.pem" -days 3650 \
            -subj "/C=${APP_ENCODE: -2}/ST=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/L=$(echo "$APP_TIMEZONE" | cut -d'/' -f2)/O=CompanyName/OU=IT Department/CN=example.com" >/dev/null 2>&1 &
        # Capture the PID of the openssl command
        openssl_pid=$!
    fi

    _stop_project

    if [[ "$openssl_pid" != "false" ]]; then
        _wait_pid_expirer "$openssl_pid"
        _log_info "Finished generating self-signed SSL certificate."
    fi
    if [[ "$dhparam_pid" != "false" ]]; then
        _wait_pid_expirer "$dhparam_pid"
        _log_info "Finished generating Diffie-Hellman parameters."
    fi

    # ## Remove deployment docker images
    # _log_info "Removing docker images"
    # yes | docker-compose -f "${DOCKER_FILE}" rm

    # ## REMOVE DOCKER IMAGES VIA NAME
    # if [[ "$YQ_IS_PRESENT" = "1" ]]; then
    #     yq '.services[].container_name' "${DOCKER_FILE}" |
    #     while IFS= read -r container_name; do
    #         _log_info "Deleted image ${container_name//\"}"
    #         yes | docker image rm "${container_name//\"}"
    #     done
    # fi
}

# Function: _post_update
# Description: Performs some post flight checks..
# Parameters: None
# Returns: None

_post_update() {
    local docker_compose_file="0"
    docker_compose_file="$(_get_project_docker_compose_file)"

    sync

    if [[ ! -f "$HOME/${GIT_REPO_NAME}/laravel/.env" ]]; then
        cp "$HOME/${GIT_REPO_NAME}/.env" "$HOME/${GIT_REPO_NAME}/laravel/.env"
        sync "$HOME/${GIT_REPO_NAME}/laravel/.env"
    fi
    chmod 770 "$HOME/${GITHUB_REPO_NAME}/laravel/.env"

    _log_info "Finished updated project files."

    if [[ ! -f "$HOME/${GIT_REPO_NAME}/laravel/public/storage" ]]; then
        ln -s /var/www/storage/app/public "$HOME/${GIT_REPO_NAME}/laravel/public/storage"
    fi
    if [[ "$docker_compose_file" != "0" ]]; then

        cd "$HOME/${GIT_REPO_NAME}" || _exit_script

        ## IF SCREEN PROGRAM IS INSTALL
        if [[ "$(_is_present screen)" = "1" ]]; then

            ## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
            if ! screen -list | grep -q "${GIT_REPO_NAME}_docker_compose_build"; then

                screen -dmS "${GIT_REPO_NAME}_docker_compose_build"

                screen -S "${GIT_REPO_NAME}_docker_compose_build" -p 0 -X stuff 'cd '"$HOME"'/'"${GIT_REPO_NAME}"' \n'
                screen -S "${GIT_REPO_NAME}_docker_compose_build" -p 0 -X stuff 'docker-compose -f '"${docker_compose_file}"' up -d --build \n'
                screen -S "${GIT_REPO_NAME}_docker_compose_build" -p 0 -X stuff 'docker-compose -f '"${docker_compose_file}"' run --user root --rm laravel chown '"$APP_USER"' /var/www/ -R; exit \n'

                ## Pipe in exit separately to ensure exit on screen
                # screen -S "${GIT_REPO_NAME}_docker_compose_build" -p 0 -X stuff 'exit\n'

            else # IF SCREEN FOUND

                _log_error "Task of building already running."
            fi

            _log_info "Building services in the background, please wait."
            sleep 3s
            while screen -list | grep -q "${GIT_REPO_NAME}_docker_compose_build"; do
                sleep 1s
            done
        else ## IF NO SCREEN PROGRAM

            docker-compose -f "${docker_compose_file}" up -d --build
            docker-compose -f "${docker_compose_file}" run --user root --rm laravel chown "$APP_USER" /var/www/ -R
        fi

        # ## CHANGE FILES AROUND FOR INSTALLING
        # _log_info "Change files around for installing"
        # docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R

        ## RESTART THE CONTAINER
        # _log_info "Restart the containers"
        # docker-compose -f "${DOCKER_FILE}" down
    fi

    ## MOVE PROJECT FILES
    mv_file_pid=$(__move_laravel_app_storage_folder)

    ## WAIT FOR FILE & FOLDER OPERATIONS TO COMPLETE
    _wait_pid_expirer "$mv_file_pid"

    sync
    ## RESET APP LOG FILES
    _log_info "Added deployment date to laravel logs"

    if [[ -d "$HOME"/"${GIT_REPO_NAME}"/laravel ]]; then

        if [[ -n $(find "$HOME/${GIT_REPO_NAME}/laravel/storage/logs/" -name "*.log" -print -quit) ]]; then
            log_files=("$HOME/${GIT_REPO_NAME}/laravel/storage/logs"/*.log)
            for file in "${log_files[@]}"; do
                {
                    echo ""
                    echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}"
                    echo ""
                } >>"$file"
                chmod 777 "$file"
            done
        fi

        if [[ -n $(find "$HOME/${GIT_REPO_NAME}/laravel/storage/logs/supervisord/" -name "*.log" -print -quit) ]]; then
            log_files=("$HOME/${GIT_REPO_NAME}"/laravel/storage/logs/supervisord/*.log)
            for file in "${log_files[@]}"; do
                {
                    echo ""
                    echo "DEPLOYMENT DATESTAMP: ${NOWDATESTAMP}"
                    echo ""
                } >>"$file"
                chmod 777 "$file"
            done
        fi
    fi

    _start_project

    screen_name="${GIT_REPO_NAME}_docker_prune"
    ## IF SCREEN PROGRAM IS INSTALL
    if [[ "$(_is_present screen)" = "1" ]]; then

        ## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
        if ! screen -list | grep -q "${screen_name}"; then

            screen -dmS "${screen_name}"
            screen -S "${screen_name}" -p 0 -X stuff 'yes | docker system prune; exit \n'
        fi

    else ## IF NO SCREEN PROGRAM

        yes | docker system prune
    fi

    # Clean-up

    _delete_old_project_files
}
