#!/bin/bash

# Author: admin@xoren.io
# Script: _functions.sh
# Link https://github.com/xorenio
# Description: Functions script.

# Defaulting variables
NOWDATESTAMP="${NOWDATESTAMP:-$(date "+%Y-%m-%d_%H-%M-%S")}"
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed 's/\.[^.]*$//')}"
SCRIPT="${SCRIPT:-$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")}"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SCRIPT_DIR_NAME="${SCRIPT_DIR_NAME:-$(basename $PWD)}"
SCRIPT_DEBUG=${SCRIPT_DEBUG:-false}

STARTING_LOCATION=${STARTING_LOCATION:-"$(pwd)"}

DEPLOYMENT_ENV_LOCATION=${DEPLOYMENT_ENV_LOCATION:-false}
DEPLOYMENT_ENV=${DEPLOYMENT_ENV:-"production"}
ISOLOCATION=${ISOLOCATION:-"GB"}
ISOSTATELOCATION=${ISOSTATELOCATION:-""}

GITHUB_REPO_OWNER="${GITHUB_REPO_OWNER:-$(git remote get-url origin | sed -n 's/.*github.com:\([^/]*\)\/.*/\1/p')}"
GITHUB_REPO_NAME="${GITHUB_REPO_NAME:-$(basename "$(git rev-parse --show-toplevel)")}"
GITHUB_REPO_URL="${GITHUB_REPO_URL:-"https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/commits"}"

SCRIPT_LOG_FILE=${SCRIPT_LOG_FILE:-"${SCRIPT_DIR}/${SCRIPT_NAME}.log"}
JSON_FILE_NAME=${JSON_FILE_NAME:-"${SCRIPT_DIR}/${SCRIPT_NAME}_${NOWDATESTAMP}.json"}
SCRIPT_RUNNING_FILE=${SCRIPT_RUNNING_FILE:-"${HOME}/${GITHUB_REPO_NAME}_running.txt"}

# START - LOG FUNCTIONS

# Function: _log_error
# Description: Logs an error message and sends it to the _log_data function.
# Parameters:
#   $1: The error message to log.
# Returns: None

_log_error() {
    _log_data "ERROR" "$1"
}

# Function: _log_info
# Description: Logs an informational message and sends it to the _log_data function.
# Parameters:
#   $1: The informational message to log.
# Returns: None

_log_info() {
    _log_data "INFO" "$1"
}

# Function: _log_debug
# Description: Logs a debug message and sends it to the _log_data function.
# Parameters:
#   $1: The debug message to log.
# Returns: None

_log_debug() {
    _log_data "DEBUG" "$1"
}

# Function: _log_success
# Description: Logs a success message and sends it to the _log_data function.
# Parameters:
#   $1: The success message to log.
# Returns: None

_log_success() {
    _log_data "SUCCESS" "$1"
}

# Function: _log_data
# Description: Adds a datestamp to the log message and sends it to the logs file and console.
# Parameters:
#   $1: The log level (e.g., ERROR, INFO, DEBUG, SUCCESS).
#   $2: The log message.
# Returns: None

_log_data() {
    local message;

    if [[ $# -eq 2 ]]; then
        message="[$1] $2"
    else
        message="$1"
    fi

    if [[ "$(_interactive_shell)" = "1" ]]; then
        # Log to the console if debug mode is enabled
        _log_console "[$(date "+%Y-%m-%d_%H-%M-%S")]$message"
    fi

    # Log to file
    _log_to_file "[$NOWDATESTAMP]$message"
}

# Function: _log_to_file
# Description: Sends the log message to the log file.
# Parameters:
#   $1: The log message.
# Returns: None

_log_to_file() {
    if [[ ! -f "${SCRIPT_LOG_FILE}" ]]; then echo "$1" > "${SCRIPT_LOG_FILE}"
    else echo "$1" >> "${SCRIPT_LOG_FILE}"
    fi
}

# Function: _log_console
# Description: Prints the log message to the console.
# Parameters:
#   $1: The log message.
# Returns: None

_log_console() {
    local _message="$1"
    echo "$_message"
}

# END - LOG FUNCTIONS




# START - RUNNING FILE

# Function: _create_running_file
# Description: Creates a running file with the current date and time.
# Parameters: None
# Returns: None

_create_running_file() {
    echo "${NOWDATESTAMP}" > "${SCRIPT_RUNNING_FILE}"
}

# Function: _check_running_file
# Description: Checks if the running file exists and exits the script if it does.
# Parameters: None
# Returns: None

_check_running_file() {
    if [[ -f "${SCRIPT_RUNNING_FILE}" ]]; then
        _log_info "Script already running."
        exit
    fi
}

# Function: _delete_running_file
# Description: Deletes the running file.
# Parameters: None
# Returns: None

_delete_running_file() {
    if [[ -f "${SCRIPT_RUNNING_FILE}" ]]; then
        rm "${SCRIPT_RUNNING_FILE}"
    fi

    cd "${STARTING_LOCATION}" || cd "$HOME" || return
}

# END - RUNNING FILE

# Function: _exit_script
# Description: Graceful exiting of script.
# Parameters: None
# Returns: None

_exit_script() {
    _delete_running_file
    cd "${STARTING_LOCATION}" || exit
    exit;
}




# START - HELPER FUNCTIONS

# Function: _is_present
# Description: Checks if the given command is present in the system's PATH.
# Parameters:
#   $1: The command to check.
# Returns:
#   1 if the command is present, otherwise void.

_is_present() { command -v "$1" &> /dev/null && echo 1; }

# Function: _is_file_open
# Description: Checks if the given file is open by any process.
# Parameters:
#   $1: The file to check.
# Returns:
#   1 if the file is open, otherwise void.

_is_file_open() { lsof "$1" &> /dev/null && echo 1; }

# Function: _interactive_shell
# Description: Checks if the script is being run from a headless terminal or cron job.
#              Returns 1 if running from a cron job or non-interactive environment, 0 otherwise.
# Parameters: None
# Returns: 1 if running from a cron job or non-interactive environment, 0 otherwise.

_interactive_shell() {
    # Check if the script is being run from a headless terminal or cron job
    if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
        if [ -t 0 ] && [ -t 1 ]; then
            # Script is being run from an interactive shell or headless terminal
            echo 1
        else
            # Script is likely being run from a cron job or non-interactive environment
            echo 0
        fi
    else
        # Script is being run from an interactive shell
        echo 1
    fi
}

# Function: _wait_pid_expirer
# Description: Waits for a process with the given PID to expire.
# Parameters:
#   $1: The PID of the process to wait for.
# Returns: None

_wait_pid_expirer() {
    while kill -0 "$1" 2>/dev/null; do
        sleep 1
    done
}

# Function: _install_cronjob
# Description: Installs a cron job from the crontab.
# Parameters:
#   $1: The cron schedule for the job. "* * * * * "
#   $2: The command of the job. "/bin/bash command-to-be-executed"
# Returns: None

_install_cronjob() {

    if [[ $# -lt 2 ]]; then
     _log_info "Missing arguments <$(echo "$1" || echo "schedule")> <$([ ${#2} -ge 1 ] && echo "$2" || echo "command")>"
     _exit_script;
    fi

    # Define the cron job entry
    local cron_schedule=$1
    local cron_job=$2
    local cron_file="/tmp/.temp_cron"

    _log_info "Installing Cron job: ${cron_job}"

    # Load the existing crontab into a temporary file
    crontab -l > "$cron_file"

    # Check if the cron job already exists
    if ! grep -q "$cron_job" "$cron_file"; then
        # Append the new cron job entry to the temporary file
        echo "$cron_schedule $cron_job" >> "$cron_file"

        # Install the updated crontab from the temporary file
        crontab "$cron_file"

        if [[ $? -eq 0 ]]; then
            _log_info "Cron job installed successfully."
        else
            _log_error "Cron job installation failed: $cron_schedule $cron_job"
        fi
    else
        _log_info "Cron job already exists."
    fi

    # Remove the temporary file
    rm "$cron_file"
}

# Function: _remove_cronjob
# Description: Uninstalls a cron job from the crontab.
# Parameters:
#   $1: The cron schedule for the job. "* * * * * "
#   $2: The command of the job. "/bin/bash command-to-be-executed"
# Returns: None

_remove_cronjob() {
    if [[ $# -lt 2 ]]; then
     _log_info "Missing arguments <$(echo "$1" || echo "schedule")> <$([ ${#2} -ge 1 ] && echo "$2" || echo "command")>"
     _exit_script;
    fi

    # Define the cron job entry
    local cron_schedule=$1
    local cron_job=$2
    local cron_file="/tmp/.temp_cron"

    _log_info "Uninstalling cronjob: ${cron_job}"


    # Load the existing crontab into a temporary file
    crontab -l > _temp_cron

    # Check if the cron job exists in the crontab
    if grep -q "$cron_job" "$cron_file"; then
        # Remove the cron job entry from the temporary file
        sed -i "/$cron_schedule $cron_job/d" "$cron_file"

        # Install the updated crontab from the temporary file
        crontab "$cron_file"

        if [[ $? -eq 0 ]]; then
            _log_info "Cron job removed successfully."
        else
            _log_error "Failed to install cronjob: $cron_schedule $cron_job"
        fi
    else
        _log_info "Cron job not found."
    fi

    # Remove the temporary file
    rm "$cron_file"
}

# Function: _install_authorized_key
# Description: Installs an SSH public key in the authorized_keys file.
# Parameters:
#   $1: The SSH public key to install.
# Returns: None

_install_authorized_key() {
    local auth_key_file="$HOME/.ssh/authorized_keys"
    local ssh_key="$1"
    local pattern="^ssh-ed25519 [[:alnum:]+/]+[=]{0,2}(\s.*)?$"

    [[ ! -d "$HOME/.ssh" ]] && mkdir -p "$HOME/.ssh"

    [[ ! -f $auth_key_file ]] && touch "$auth_key_file"

    # Check if the content already exists in the authorized_keys file
    _log_info "Public ssh key: ${ssh_key}"

    # Check if the content matches the expected pattern
    if [[ $ssh_key =~ $pattern ]]; then
        if grep -qF "$ssh_key" "$auth_key_file"; then
            _log_success "Already exists in $HOME/authorized_keys"
        else
            # Append the content to the authorized_keys file
            echo "$ssh_key" >> "$auth_key_file"
            _log_success "Installed in $HOME/authorized_keys."
        fi
    else
        _log_error "Public Check failed check"
    fi
}
# END - HELPER FUNCTIONS




# START - HELPER VARIABLES

# shellcheck disable=SC2034
APT_IS_PRESENT="$(_is_present apt-get)"
# shellcheck disable=SC2034
YUM_IS_PRESENT="$(_is_present yum)"
# shellcheck disable=SC2034
PACMAN_IS_PRESENT="$(_is_present pacman)"
# shellcheck disable=SC2034
SCREEN_IS_PRESENT="$(_is_present screen)"
# shellcheck disable=SC2034
WHOIS_IS_PRESENT="$(_is_present whois)"
# shellcheck disable=SC2034
CURL_IS_PRESENT="$(_is_present curl)"
# END - HELPER VARIABLES




# START - SET DISTRO VARIABLES

if [ "$APT_IS_PRESENT" ]; then
    PM_COMMAND=apt-get
    PM_INSTALL=(install -y)
    PREREQ_PACKAGES="sudo tmux screen docker docker-compose wget whois net-tools jq htop curl git certbot python3-certbot-nginx nginx zip gzip fail2ban dirmngr software-properties-common apt-transport-https gpg-agent dnsutils unzip"
elif [ "$YUM_IS_PRESENT" ]; then
    PM_COMMAND=yum
    PM_INSTALL=(-y install)
    PREREQ_PACKAGES="sudo tmux screen docker docker-compose wget whois net-tools jq htop curl git certbot python3-certbot-nginx nginx zip gzip fail2ban wget unzip bind-utils tar"
elif [ "$PACMAN_IS_PRESENT" ]; then
    PM_COMMAND=pacman
    PM_INSTALL=(-S --noconfirm)
    PREREQ_PACKAGES="sudo tmux screen docker docker-compose wget whois net-tools jq htop curl git certbot nginx zip gzip fail2ban unzip dnsutils tar"
elif [ "$ZYPPER_IS_PRESENT" ]; then
    PM_COMMAND=zypper
    PM_INSTALL=(install -y)
    PREREQ_PACKAGES="sudo tmux screen docker docker-compose wget whois net-tools jq htop curl git certbot python3-certbot-nginx nginx zip gzip fail2ban wget unzip bind-utils tar"
else
    _log_error "This system doesn't appear to be supported. No supported package manager (apt/yum/pacman/zypper) was found."
    exit
fi
# END - SET DISTRO VARIABLES




# START - GEOLCATION FUNCTIONS

# Function: _valid_ip
# Description: Checks if the given IP address is valid.
# Parameters:
#   $1: The IP address to validate.
# Returns:
#   0 if the IP address is valid, 1 otherwise.

_valid_ip() {
    local ip="$1"
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ && $(IFS='.'; set -- "$ip"; (($1<=255 && $2<=255 && $3<=255 && $4<=255))) ]]
}

# Function: _set_location_var
# Description: Retrieves the public IP address and sets the ISOLOCATION variable based on the country.
# Parameters: None
# Returns: None

_set_location_var() {
    local public_ip
    public_ip=$(_get_public_ip)

    if _valid_ip "${public_ip}"; then

        ISOLOCATION="$(whois "$public_ip" | grep -iE ^country:)"
        ISOLOCATION="$(echo "$ISOLOCATION" | head -n 1 )"
        ISOLOCATION="${ISOLOCATION:(-2)}"
    fi
}

# END - GEOLOCATION FUNCTIONS




# START - PROJECT FUNCTIONS

# Function: _check_project_secrets
# Description: Checks if the secrets file exists and prompts user to create it if it doesn't exist.
# Parameters: None
# Returns: None

_check_project_secrets() {
    if [[ ! -f "$HOME/.${GITHUB_REPO_NAME}" ]]; then

        _log_error ""
        _log_error "Failed deployment ${NOWDATESTAMP}"
        _log_error ""
        _log_error "Missing twisted var file $HOME/.${GITHUB_REPO_NAME}"

        if [[ "$(_interactive_shell)" = "true" ]]; then
            read -rp "Write secrets file? [Y/n] (empty: no): " write_file
            if [[ $write_file =~ ^(Yes|yes|y)$ ]]; then
                _write_project_secrets
            fi
        fi
        _exit_script
    fi
}

# Function: _load_project_secrets
# Description: Checks if the secrets file exists and load it.
# Parameters: None
# Returns: None

_load_project_secrets() {
    # shellcheck disable=SC1090
    [[ -f "$HOME/.${GITHUB_REPO_NAME}" ]] && source "$HOME/.${GITHUB_REPO_NAME}" ##|| echo 0
}

# Function: _write_project_secrets
# Description: Writes environment variables to a file in the user's home directory.
# Parameters: None
# Returns: None

_write_project_secrets() {

    cat > "$HOME/.${GITHUB_REPO_NAME}" <<EOF
# Deployment
APP_KEY=base64:
APP_USER_UUID=1000
APP_USER=laravel
DB_HOST=localhost
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="password"
DEPLOYMENT_ENV=production
DEPLOYMENT_TIMEZONE=Europe/London
DEPLOYMENT_ENCODE=en_GB
SSH_PUB_KEY="https://raw.githubusercontent.com/xorenio/ssh/main/id_ed25519_2.pub"
SSH_BACKUP_PUB_KEY="https://raw.githubusercontent.com/xorenio/ssh/main/id_ed25519.pub"
GIT_EMAIL="john@xoren.io"
GIT_NAME="John J"
EOF
    chmod 770 "$HOME"/."${GITHUB_REPO_NAME}"
    _log_info "Writen env vars file $HOME/.${GITHUB_REPO_NAME}"
}

# Function: _replace_env_project_secrets
# Description: Replaces the environment variables in the configuration file with their corresponding values.
# Parameters: None
# Returns: None
_replace_env_project_secrets() {

    _log_info "START: Replacing APP environment variables"

    ## CHECK IF FILE DOESNT EXIST AND CREATE IT
    if [[ ! -f "$HOME/.${GITHUB_REPO_NAME}" ]]; then
        _write_project_secrets
    fi
    sed -i 's/\r//g' "$HOME"/."${GITHUB_REPO_NAME}"
    ## PROPERGATE ENV FILE
    [[ ! -f "$HOME/${GITHUB_REPO_NAME}/.env" ]] && cp "$HOME/${GITHUB_REPO_NAME}/.env.$DEPLOYMENT_ENV" "$HOME/${GITHUB_REPO_NAME}/.env"

    sync "$HOME/${GITHUB_REPO_NAME}/.env"

    local first_letter name value;
    ## READ EACH LINE OF CONFIG FILE
    while read -r CONFIGLINE;
    do
        ## GET FOR CHECK FIRST CHAR IN CONFIG LINE
        first_letter=${CONFIGLINE:0:1}

        ## CHECK FIRST LETTER ISN'T # & LINE LETTER LENGTH IS LONGER THAN 3
        if [[ $first_letter != " " && $first_letter != "#" && ${#CONFIGLINE} -gt 3 ]]; then

            ## CHECK FOR = IN CONFIG LINE SEPARATE IF STATEMENT FORMATTED DIFFERENTLY TO WORK
            if echo "$CONFIGLINE" | grep -F = &>/dev/null; then
                name=$(echo "$CONFIGLINE" | cut -d '=' -f 1)
                value=$(echo "$CONFIGLINE" | cut -d '=' -f 2-)
                while grep -F "\"<$name>\"" "$HOME/${GITHUB_REPO_NAME}/.env" &>/dev/null; do
                    sed -i "s|\"<$name>\"|$value|" "$HOME/${GITHUB_REPO_NAME}/.env"
                    sync "$HOME/${GITHUB_REPO_NAME}/.env"
                    sleep 1
                done
            fi
        fi
    done < "$HOME/.${GITHUB_REPO_NAME}"

    ## REPLACED DEPLOYMENT VARS
    while grep -F "\"<DEPLOYMENT_VERSION>\"" "$HOME/${GITHUB_REPO_NAME}/.env" &>/dev/null; do
        sed -i "s|\"<DEPLOYMENT_VERSION>\"|$LATEST_PROJECT_SHA|" "$HOME/${GITHUB_REPO_NAME}/.env"
        sync -d "$HOME/${GITHUB_REPO_NAME}/.env"
        sleep 1
    done
    sed -i "s|\"<DEPLOYMENT_AT>\"|$NOWDATESTAMP|" "$HOME/${GITHUB_REPO_NAME}/.env"
    sync -d "$HOME/${GITHUB_REPO_NAME}/.env"


    _log_info "END: Replacing APP environment variables"
}

# END - PROJECT FUNCTIONS




# START - UPDATE CRONJOB

# Function: _setup_update_cron
# Description: Sets up the update project cronjob.
# Parameters: None
# Returns:
#   0 if failed cronjob install.

_install_update_cron() {
    # shellcheck disable=SC2005
    echo "$(_install_cronjob "*/5 * * * *" "/bin/bash $HOME/${GITHUB_REPO_NAME}/${SCRIPT} repo:check")"
}

# Function: _install_update_cron
# Description: Sets up the update project cronjob.
# Parameters: None
# Returns:
#   0 if failed cronjob uninstall.

_remove_update_cron() {
    # shellcheck disable=SC2005
    echo "$(_remove_cronjob "*/5 * * * *" "/bin/bash $HOME/${GITHUB_REPO_NAME}/${SCRIPT} repo:check")"
}
# END - UPDATE CRONJOB




# START - GITHUB TOKEN

# Function: _check_github_token
# Description: Check $GITHUB_TOKEN variable has been set and matches the github personal token pattern
# Parameters: None
# Returns:
#   1 if successfully loaded github token and matches pattern

_check_github_token() {
    pattern="^ghp_[a-zA-Z0-9]{36}$"
    [[ ${GITHUB_TOKEN:-"ghp_##"} =~ $pattern ]] && echo 1;
}

# Function: _check_github_token_file
# Description: Check the location for the github token file.
# Parameters: None
# Returns:
#   1 if github token file exists, otherwise 0.

_check_github_token_file() {
    [[ -f "$HOME/.github_token" ]] && echo 1
}

# Function: _load_github_token
# Description: If github token already has been loaded or check and loads from file then validate.
# Parameters: None
# Returns:
#   1 if github token already loaded or loads token from file and matches pattern, otherwise 0.

_load_github_token() {
    if [[ $(_check_github_token) = "1" ]]; then
        return
    fi

    if [[ "$(_check_github_token_file)" = "1" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.github_token" || echo "Failed import of github_token"
    fi
}

# Function: _write_github_token
# Description: Given a gh token or from user prompt, validate and creates .github_token file.
# Parameters:
#   $1: optional github token
# Returns:
#   1 if successfully installed github token.

#shellcheck disable=SC2120
_write_github_token() {
    pattern="^ghp_[a-zA-Z0-9]{36}$"
    local token;

    if [[ $# -ge 1 ]]; then
        token=$1
    elif [[ "$(_interactive_shell)" = "1" ]]; then
        read -rp "Please provide? [Y/n] (empty: cancel): " input_token
        token="$input_token"
        if [[ ! $token =~ $pattern ]]; then
            # _log_error "Missing github token file .github_token"
            _log_error "GITHUB_TOKEN=ghp_azAZ09azAZ09azAZ09azAZ09azAZ09azAZ09"
            _log_error "public_repo, read:packages, repo:status, repo_deployment"
            _log_error "Invalid github personal access token."
            _exit_script
        fi
    fi
    if [[ $token =~ $pattern ]]; then
        echo "#" > "$HOME"/.github_token
        echo "GITHUB_TOKEN=$token" >> "$HOME"/.github_token
        echo "" >> "$HOME"/.github_token
        chmod 700 "$HOME"/.github_token
        _load_github_token
        echo 1
    else
        _log_error "Invalid github personal access token."
        _exit_script
    fi
}
# END - GITHUB TOKEN




# START - GITHUB API

_get_project_github_latest_sha() {

    _load_github_token
    if [[ "$(_check_github_token)" = "0" ]]; then
        _write_github_token
    fi

    local curl_data gh_sha;
    curl_data=$( curl -s -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version:2022-11-28" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$GITHUB_REPO_URL")

    if [[ $(echo "$curl_data" | jq -r .message 2> /dev/null && echo 1) ]]; then
        _log_error "$(echo "$curl_data" | jq .message)"
        echo 0;
        return;
    fi

    if [[ $(echo "$curl_data" | jq -r .[0].commit.tree.sha 2> /dev/null && echo 1) ]]; then
        gh_sha="$(echo "$curl_data" | jq .[0].commit.tree.sha)"
        echo "${gh_sha//\"}"
        return;
    fi
}
# END - GITHUB API




# START - UPDATE FUNCTIONS

# Function: _update
# Description: Performs re-deployment of the project by cloning a fresh copy from GitHub and updating project files.
#              It also moves the old project folder to a backup location.
#              The function replaces environment variables and propagates the environment file.
# Parameters: None
# Returns: None

_update() {

    if [[ -f "$HOME/${GITHUB_REPO_NAME}/_update.sh" ]]; then

        # shellcheck disable=SC1090
        source "$HOME/${GITHUB_REPO_NAME}/_update.sh"
    else

        _log_to_file ""
        _log_to_file "Re-deployment Started"
        _log_to_file "====================="
        _log_to_file "env: ${DEPLOYMENT_ENV}"

        ## LEAVE PROJECT DIRECTORY
        cd "$HOME" || _exit_script

        ## RENAME OLD PROJECT DIRECTORY
        _log_to_file "Moving old project folder."

        [[ -f "$HOME/$GITHUB_REPO_NAME/.env" ]] && rm "$HOME/$GITHUB_REPO_NAME/.env"

        mv -u -f "$HOME/$GITHUB_REPO_NAME" "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}"

        ## WAIT FOR INODE CHANGES
        sync

        ## CLONE FRESH COPY OF PROJECT / no log file
        git clone git@github.com:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git

        ## WAIT FOR INODE CHANGES
        sync

        mv "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}/"*.log "$HOME/${GITHUB_REPO_NAME}/"
        mv "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}/"*.json "$HOME/${GITHUB_REPO_NAME}/"

        _log_to_file "Finished cloning fresh copy from github ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}."

        ## REPLACE ENV FILES
        _log_to_file "Moving project secrets in to .env file."
        _replace_env_project_secrets

        _log_info "Finished updated project files."
        _log_to_file ""
    fi
}

# Function: _check_update
# Description: Checks if the local version matches the remote version of the repository.
# If the versions match, the script will exit.
# If the versions do not match, the script will perform an update and update the local version.
# Parameters: None
# Returns: None

_check_update() {
    LATEST_PROJECT_SHA="$(_get_project_github_latest_sha)"

    if [[ "${LATEST_PROJECT_SHA}" = "0" ]]; then
        _log_error "Failed to fetching SHA from api.github.com"
        _exit_script
    fi

    ## CHECK FOR DEFAULT VARS
    if [[ "${DEPLOYMENT_VERSION}" = "<DEPLOYMENT_VERSION>" ]]; then

        ## replace with requested data version
        _log_error "Current version <DEPLOYMENT_VERSION> AKA deployment failure somewhere"
        sed -i 's|"<DEPLOYMENT_VERSION>"|'${LATEST_PROJECT_SHA}'|' "$HOME/${GITHUB_REPO_NAME}/.env"
    elif [[ "${DEPLOYMENT_VERSION}" = "DEV" ]]; then

        _log_error "Updating is disabled in development"
    else

        ## IF LOCAL VERSION AND REMOTE VERSION ARE THE SAME
        if [[ "${DEPLOYMENT_VERSION}" = "${LATEST_PROJECT_SHA}" ]]; then

            _log_info "VERSION MATCH, ending script"
            _exit_script
        fi
        _update
        sed -i 's|"<DEPLOYMENT_VERSION>"|'${LATEST_PROJECT_SHA}'|' "$HOME/${GITHUB_REPO_NAME}/.env"
    fi
}

# Function: _delete_old_project_files
# Description: Deletes old project files.
# Parameters: None
# Returns: None

_delete_old_project_files() {

    local old_project_folder_byte_size
    old_project_folder_byte_size=$(du "$HOME/${GITHUB_REPO_NAME}_${NOWDATESTAMP}" -sc | grep total)

    old_project_folder_byte_size=${old_project_folder_byte_size/" "/""}
    old_project_folder_byte_size=${old_project_folder_byte_size/" "/""}

    if [[ old_project_folder_byte_size -le 1175400 ]]; then
        echo "Not yet"
        # rm -R
    fi
}
# END - UPDATE FUNCTIONS




# START - COMPLETION
# _script_completion() {
#     local cur prev opts
#     COMPREPLY=()
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
#     opts="user:add linux:install setup:hpages setup:ssh:keys setup:certbot setup:git:profile setup:well-known certbot:add system:json repo:check repo:update queue:worker config:backup config:restore version:local version:remote"

#     case "${prev}" in
#         certbot:add)
#             # Custom completion for certbot:add option
#             COMPREPLY=($(compgen -f -- "${cur}"))
#             return 0
#             ;;
#         user:add)
#             # Custom completion for user:add option
#             COMPREPLY=($(compgen -f -- "${cur}"))
#             return 0
#             ;;
#         *)
#             ;;
#     esac

#     COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
#     return 0
# }

# complete -F _script_completion "${SCRIPT}"

# END - COMPLETION




# START - SETUP

# Function: _setup
# Description: Sets up the Linux environment for hosting.
# Parameters: None
# Returns: None

_setup() {

    _install_cronjob "*/5 * * * *" "/bin/bash $HOME/${GITHUB_REPO_NAME}/${SCRIPT} repo:check"
    _setup_ssh_key
    _setup_git
}

# Function: _setup_ssh_key
# Description: Sets up an ED25519 ssh key for the root user.
# Parameters: None
# Returns: None

_setup_ssh_key() {
    _log_info "Setting up ssh keys"

    local first_key second_key;

    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        _log_info "Creating ed25519 ssh key"
        ssh-keygen -t ed25519 -N "" -C "${GIT_EMAIL}" -f "$HOME/.ssh/id_ed25519"  > /dev/null 2>&1
        _log_info "Public: $(cat "$HOME/.ssh/id_ed25519.pub")"
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
    fi

    _log_info "Loading SSH key: ${SSH_PUB_KEY}"
    _log_info "Loading SSH key: ${SSH_BACKUP_PUB_KEY}"

    curl -sSf "$SSH_PUB_KEY" -o "/tmp/FIRST_KEY.pub"
    curl -sSf "$SSH_BACKUP_PUB_KEY" -o "/tmp/SECOND_KEY.pub"

    # Read the content of the downloaded file
    first_key=$(cat "/tmp/FIRST_KEY.pub")
    second_key=$(cat "/tmp/SECOND_KEY.pub")

    _install_authorized_key "$first_key"
    _install_authorized_key "$second_key"

    # Clean up the temporary file
    rm "/tmp/FIRST_KEY.pub"
    rm "/tmp/SECOND_KEY.pub"
}


# Function: _setup_git
# Description: Sets up the local git profile by configuring user name and email.
# Parameters: None
# Returns: None

_setup_git() {
    _log_info "Setup local git profile"

    git config --global user.name "${GIT_NAME}"
    git config --global user.email "${GIT_EMAIL}"
}

# END -SETUP