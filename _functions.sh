#!/bin/bash

# Author: admin@xoren.io
# Script: _functions.sh
# Link https://github.com/xorenio
# Description: Functions script.

###
#INDEX
## Function
# _log_error()
# _log_info()
# _log_debug()
# _log_success()
# _log_data()
# _log_to_file()
# _log_console()
# _create_running_file()
# _check_running_file()
# _delete_running_file()
# _exit_script()
# _in_working_schedule()
# _check_working_schedule()
# _is_present()
# _is_file_open()
# _interactive_shell()
# _wait_pid_expirer()
# _install_cronjob()
# _remove_cronjob()
# _install_authorized_key()
# _calculate_folder_size()
# _delete_old_project_files()
# _valid_ip()
# _set_location_var()
# _check_project_secrets()
# _load_project_secrets()
# _write_project_secrets()
# _replace_env_project_secrets()
# _get_project_docker_compose_file()
# _install_update_cron()
# _remove_update_cron()
# _git_service_provider()
# _check_github_token()
# _check_github_token_file()
# _load_github_token()
# _write_github_token()
# _get_project_github_latest_sha()
# _check_onedev_token()
# _check_onedev_file()
# _load_onedev_token()
# _write_onedev_token()
# _get_project_onedev_latest_sha()
# _download_project_files()
# _update()
# _set_latest_sha()
# _check_latest_sha()
# _check_update()
# _script_completion()
# _setup()

# Defaulting variables
NOWDATESTAMP="${NOWDATESTAMP:-$(date "+%Y-%m-%d_%H-%M-%S")}"

# This script variables
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed 's/\.[^.]*$//')}"
SCRIPT="${SCRIPT:-$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")}"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SCRIPT_DIR_NAME="${SCRIPT_DIR_NAME:-$(basename "$PWD")}"
SCRIPT_DEBUG=${SCRIPT_DEBUG:-false}

# Terminal starting directory
STARTING_LOCATION=${STARTING_LOCATION:-"$(pwd)"}

# Deployment environment
DEPLOYMENT_ENV=${DEPLOYMENT_ENV:-"production"}

# Enable location targeted deployment
DEPLOYMENT_ENV_LOCATION=${DEPLOYMENT_ENV_LOCATION:-false}

# Deployment location
ISOLOCATION=${ISOLOCATION:-"GB"}
ISOSTATELOCATION=${ISOSTATELOCATION:-""}

# Git repo name
GIT_REPO_NAME="${GIT_REPO_NAME:-$(basename "$(git rev-parse --show-toplevel)")}"

# if using GitHub, Github Details if not ignore
GITHUB_REPO_OWNER="${GITHUB_REPO_OWNER:-$(git remote get-url origin | sed -n 's/.*github.com:\([^/]*\)\/.*/\1/p')}"
GITHUB_REPO_URL="${GITHUB_REPO_URL:-"https://api.github.com/repos/$GITHUB_REPO_OWNER/$GIT_REPO_NAME/commits"}"

SCRIPT_LOG_FILE=${SCRIPT_LOG_FILE:-"${SCRIPT_DIR}/${SCRIPT_NAME}.log"}
JSON_FILE_NAME=${JSON_FILE_NAME:-"${SCRIPT_DIR}/${SCRIPT_NAME}_${NOWDATESTAMP}.json"}
SCRIPT_RUNNING_FILE=${SCRIPT_RUNNING_FILE:-"${HOME}/${GIT_REPO_NAME}_running.txt"}

LATEST_PROJECT_SHA=${LATEST_PROJECT_SHA:-0}
# Working Schedule
# This is referenced in the update check function and will exclude updating in given time frames, or false to disable
# Define a single string with time ranges, where ranges can be specified like 1-5:07:00-16:00
# Format: day(s):start_time-end_time|...
# Example:
# Monday to Friday: 1-5:07:00-16:00
# Saturday and Sunday: 6-7:09:00-15:00
# WORKING_SCHEDULE=${WORKING_SCHEDULE:-"1-5:07:00-16:00|6:20:00-23:59"}
WORKING_SCHEDULE=false

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
    local message

    # Check for two params
    if [[ $# -eq 2 ]]; then
        # Add prefix to message
        message="[$1] $2"
    else
        # No prefix
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
    # If not existing log file directory return
    if [[ ! -d $(pwd "${SCRIPT_LOG_FILE}") ]]; then
        return
    fi
    # If not existing log file create
    if [[ ! -f "${SCRIPT_LOG_FILE}" ]]; then
        echo "$1" >"${SCRIPT_LOG_FILE}"
    # If existing log file add to it
    else
        echo "$1" >>"${SCRIPT_LOG_FILE}"
    fi
}

# Function: _log_console
# Description: Prints the log message to the console.
# Parameters:
#   $1: The log message.
# Returns:
#   $1: The log message.

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
    echo "${NOWDATESTAMP}" >"${SCRIPT_RUNNING_FILE}"
}

# Function: _check_running_file
# Description: Checks if the running file exists and exits the script if it does.
# Parameters: None
# Returns: None

_check_running_file() {
    # If running file exists
    if [[ -f "${SCRIPT_RUNNING_FILE}" ]]; then
        # Log and hard exit
        _log_info "Script already running."
        exit
    fi
}

# Function: _delete_running_file
# Description: Deletes the running file.
# Parameters: None
# Returns: None

_delete_running_file() {
    # If running file exists delete it
    if [[ -f "${SCRIPT_RUNNING_FILE}" ]]; then
        rm "${SCRIPT_RUNNING_FILE}"
    fi
    # Return users tty to starting directory or home or do nothing.
    cd "${STARTING_LOCATION}" || cd "$HOME" || return
}

# END - RUNNING FILE

# Function: _exit_script
# Description: Graceful exiting of script.
# Parameters: None
# Returns: None

_exit_script() {

    # Delete running file
    _delete_running_file

    # Return users tty to starting directory or home or do nothing.
    cd "${STARTING_LOCATION}" || cd "$HOME" || exit

    # Making sure we do stop the script.
    exit
}

# START - WORKING SCHEDULE

# Function: _in_working_schedule
# Description: Validate working schedule variable and checks if in time.
# Parameters: None
# Returns:
#   0: Not in working hours
#   1: In configured working hours.
#   exit: Invalid working schedule variable.

_in_working_schedule() {
    local pattern="^[0-7]-[0-7]:[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$"
    if [[ ! $WORKING_SCHEDULE =~ $pattern ]]; then
        _log_error "Invalid WORKING_SCHEDULE format. Please use the format: day(s):start_time-end_time."
        _exit_script
    fi

    # Get the current day of the week (1=Monday, 2=Tuesday, ..., 7=Sunday)
    day_of_week=$(date +%u)

    # Get the current hour (in 24-hour format)
    current_hour=$(date +%H)

    # Define a single string with time ranges, where ranges can be specified like 1-5:07:00-16:00
    # Format: day(s):start_time-end_time|...
    # e.g., "1-5:07:00-16:00|6:09:00-15:00|7:09:00-15:00"
    # SCRIPT_SCHEDULE="1-5:07:00-16:00|6:09:00-15:00|7:09:00-15:00"

    # Split the time_ranges string into an array using the pipe '|' delimiter
    IFS="|" read -ra ranges <<<"$WORKING_SCHEDULE"

    # Initialize a variable to store the current day's time range
    current_day_schedule=""

    # Iterate through the time ranges to find the one that matches the current day
    for range in "${ranges[@]}"; do
        days="${range%%:*}"
        times="${range#*:}"
        start_day="${days%%-*}"
        end_day="${days##*-}"

        if [ "$day_of_week" -ge "$start_day" ] && [ "$day_of_week" -le "$end_day" ]; then
            current_day_schedule="$times"
            break
        fi
    done

    if [ -n "$current_day_schedule" ]; then
        start_time="${current_day_schedule%%-*}"
        end_time="${current_day_schedule##*-}"

        if [ "$current_hour" -ge "$start_time" ] && [ "$current_hour" -le "$end_time" ]; then
            _log_error "Script is running within the allowed time range. Stopping..."
            echo 1
            return
        fi
    fi
    echo 0
}

# Function: _check_working_schedule
# Description: Check working variable doesn't equals false and runs in working schedule function
# Parameters: None
# Returns:
#   0: Not in working hours
#   1: In configured working hours

_check_working_schedule() {

    # Check for update exclude
    if [[ "$WORKING_SCHEDULE" != "false" ]]; then

        _in_working_schedule
        return
    fi
    echo 0
}
# END - WORKING SCHEDULE

# START - HELPER FUNCTIONS

# Function: _is_present
# Description: Checks if the given command is present in the system's PATH.
# Parameters:
#   $1: The command to check.
# Returns:
#   1 if the command is present, otherwise void.

_is_present() { command -v "$1" &>/dev/null && echo 1; }

# Function: _is_file_open
# Description: Checks if the given file is open by any process.
# Parameters:
#   $1: The file to check.
# Returns:
#   1 if the file is open, otherwise void.

_is_file_open() { lsof "$1" &>/dev/null && echo 1; }

# Function: _interactive_shell
# Description: Checks if the script is being run from a headless terminal or cron job.
#              Returns 1 if running from a cron job or non-interactive environment, 0 otherwise.
# Parameters: None
# Returns:
#   1 if running from a cron job or non-interactive environment
#   0 otherwise.

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
    # If sig is 0, then no signal is sent, but error checking is still performed.
    while kill -0 "$1" 2>/dev/null; do
        sleep 1s
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
        _exit_script
    fi

    # Define the cron job entry
    local cron_schedule=$1
    local cron_job=$2
    local cron_file="/tmp/.temp_cron"

    _log_info "Installing Cron job: ${cron_job}"

    # Load the existing crontab into a temporary file
    crontab -l >"$cron_file"

    # Check if the cron job already exists
    if ! grep -q "$cron_job" "$cron_file"; then
        # Append the new cron job entry to the temporary file
        echo "$cron_schedule $cron_job" >>"$cron_file"

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
        _exit_script
    fi

    # Define the cron job entry
    local cron_schedule=$1
    local cron_job=$2
    local cron_file="/tmp/.temp_cron"

    _log_info "Removing cronjob: ${cron_job}"

    # Load the existing crontab into a temporary file
    crontab -l >_temp_cron

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
            echo "$ssh_key" >>"$auth_key_file"
            _log_success "Installed in $HOME/authorized_keys."
        fi
    else
        _log_error "Public Check failed check"
    fi
}

# Function: _calculate_folder_size
# Description: Function to calculate the size of a folder excluding specific directories.
# Parameters: None
# Returns: None

_calculate_folder_size() {
    local folder=$1
    local exclude_dirs=(".git" "laravel/node_modules" "laravel/vendor")
    local exclude_opts=""

    for dir in "${exclude_dirs[@]}"; do
        exclude_opts+="--exclude='${folder}'/'${dir}' "
    done

    du -s --exclude='.*/' "$exclude_opts" "$folder" | awk '{print $1}'
}

# Function: _delete_old_project_files
# Description: Deletes old project files.
# Parameters: None
# Returns: None

_delete_old_project_files() {

    [[ ! -d "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}" ]] && return
    local old_size new_size size_difference

    # Compare the size of the old and new project folders
    old_size=$(_calculate_folder_size "$HOME/${GIT_REPO_NAME}")
    new_size=$(_calculate_folder_size "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}")
    size_difference=$(echo "scale=2; ($old_size - $new_size) / $old_size * 100" | bc)

    # Check if the old project folder is within 10% of the size of the new project
    if (($(echo "$size_difference <= 10" | bc -l))); then
        _log_info "Deleted: $HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}"
        yes | rm -rf "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}"
    else
        _log_info "NOT Deleted: $HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}"
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
ZYPPER_IS_PRESENT="$(_is_present zypper)"
# shellcheck disable=SC2034
DNF_IS_PRESENT="$(_is_present dnf)"
# shellcheck disable=SC2034
DOCKER_IS_PRESENT="$(_is_present docker)"
# END - HELPER VARIABLES

# START - SET DISTRO VARIABLES

if [[ "$APT_IS_PRESENT" = "1" ]]; then
    PM_COMMAND=apt-get
    PM_INSTALL=(install -y)
    PREREQ_PACKAGES="docker docker-compose whois jq yq curl git bc parallel screen"
elif [[ "$YUM_IS_PRESENT" = "1" ]]; then
    PM_COMMAND=yum
    PM_INSTALL=(-y install)
    PREREQ_PACKAGES="docker docker-compose whois jq yq curl git bc parallel screen"
elif [[ "$PACMAN_IS_PRESENT" = "1" ]]; then
    PM_COMMAND=pacman
    PM_INSTALL=(-S --noconfirm)
    PREREQ_PACKAGES="docker docker-compose whois jq yq curl git bc parallel screen"
elif [[ "$ZYPPER_IS_PRESENT" = "1" ]]; then
    PM_COMMAND=zypper
    PM_INSTALL=(install -y)
    PREREQ_PACKAGES="docker docker-compose whois jq yq curl git bc parallel screen"
elif [[ "$DNF_IS_PRESENT" = "1" ]]; then
    PM_COMMAND=dnf
    PM_INSTALL=(install -y)
    PREREQ_PACKAGES="docker docker-compose whois jq yq curl git bc parallel screen"
else
    _log_error "This system doesn't appear to be supported. No supported package manager (apt/yum/pacman/zypper/dnf) was found."
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
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ && $(
        IFS='.'
        set -- "$ip"
        (($1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255))
    ) ]]
}

# Function: _set_location_var
# Description: Retrieves the public IP address and sets the ISOLOCATION variable based on the country.
# Parameters: None
# Returns: None

_set_location_var() {
    local public_ip
    public_ip=$(_get_public_ip)

    if _valid_ip "${public_ip}"; then
        # Whois public ip and grep first country code
        ISOLOCATION="$(whois "$public_ip" -a | grep -iE ^country: | head -n 1)"
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
    # If no secrets file
    if [[ ! -f "$HOME/.${GIT_REPO_NAME}" ]]; then

        # Log the missing file
        _log_error ""
        _log_error "Failed deployment ${NOWDATESTAMP}"
        _log_error ""
        _log_error "Missing twisted var file $HOME/.${GIT_REPO_NAME}"

        # If script ran from tty
        if [[ "$(_interactive_shell)" = "1" ]]; then
            # Ask user if they want to write secret file
            read -rp "Write secrets file? [Y/n] (empty: no): " write_file
            if [[ $write_file =~ ^(YES|Yes|yes|Y|y)$ ]]; then
                _write_project_secrets
            fi
        fi
        # Exit script
        _exit_script
    fi
}

# Function: _load_project_secrets
# Description: Checks if the secrets file exists and load it.
# Parameters: None
# Returns: None

_load_project_secrets() {
    # shellcheck disable=SC1090
    [[ -f "$HOME/.${GIT_REPO_NAME}" ]] && source "$HOME/.${GIT_REPO_NAME}" ##|| echo 0
}

# Function: _write_project_secrets
# Description: Writes environment variables to a file in the user's home directory.
# Parameters: None
# Returns: None

_write_project_secrets() {

    cat >"$HOME/.${GIT_REPO_NAME}" <<EOF
# Deployment
DEPLOYMENT_ENV=production
DEPLOYMENT_TIMEZONE=Europe/London
DEPLOYMENT_ENCODE=en_GB
# APP
APP_KEY="base64:$(openssl rand -base64 32)"
APP_USER_UUID=$UID
APP_USER_GUID=$(id -g)
APP_USER=$(whoami)
# DATABASE
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="password"
FORWARD_DB_PORT=63306
# MAILER
MAIL_MAILER=smtp
MAIL_HOST=outbound.mailhop.org
MAIL_PORT=587
MAIL_USERNAME=""
MAIL_PASSWORD="outbound.mailhop.password"
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@m.myrank.ing"
MAIL_TO_ADDRESS="admin@myrank.ing"
# CLOUDFLARE
CF_TOKEN=""
CF_ACCOUNT_ID=""
CF_DOMAIN_ID="myrank.ing"
CF_PROJECT_ID="myranking"
EOF
    chmod 700 "$HOME"/."${GIT_REPO_NAME}"
    _log_info "Writen env vars file $HOME/.${GIT_REPO_NAME}"
}

# Function: _replace_env_project_secrets
# Description: Replaces the environment variables in the configuration file with their corresponding values.
# Parameters: None
# Returns: None

_replace_env_project_secrets() {

    _check_latest_sha
    # LATEST_PROJECT_SHA="$(_check_latest_sha true)"

    _log_info "Replacing APP environment variables"

    # Check if secrets file doesn't exists and
    if [[ ! -f "$HOME/.${GIT_REPO_NAME}" ]]; then
        # Call function to help create it
        _write_project_secrets
    fi

    # Remove window line endings
    sed -i 's/\r//g' "$HOME/.${GIT_REPO_NAME}"

    if [ -f "$HOME/${GIT_REPO_NAME}/.env.${DEPLOYMENT_ENV}" ]; then
        sed -i 's/\r//g' "$HOME/${GIT_REPO_NAME}/.env.${DEPLOYMENT_ENV}"
    fi

    # Copy the deployment version of .env file
    [[ ! -f "$HOME/${GIT_REPO_NAME}/.env" ]] && cp "$HOME/${GIT_REPO_NAME}/.env.${DEPLOYMENT_ENV}" "$HOME/${GIT_REPO_NAME}/.env"

    # Call sync for .env inode
    sync "$HOME/${GIT_REPO_NAME}/.env"

    # Make it excusable
    chmod 700 "$HOME/${GIT_REPO_NAME}/.env"

    # Call sync for .env inode
    local first_letter sec_name sec_value

    # Read line by line secrets file
    while read -r CONFIGLINE; do
        # Get the first letter of line
        first_letter=${CONFIGLINE:0:1}

        # Check first letter isnt a space or # and line length is greater then 3
        if [[ $first_letter != " " && $first_letter != "#" && ${#CONFIGLINE} -gt 3 ]]; then

            # Check for "=" in line
            if echo "$CONFIGLINE" | grep -F = &>/dev/null; then

                # Get the variable name
                sec_name="$(echo "$CONFIGLINE" | cut -d '=' -f 1)"

                # Get the variable value
                sec_value="$(echo "$CONFIGLINE" | cut -d '=' -f 2-)"

                # While loop grep .env file to replace all found configs
                while [[ "$(grep -oF "\"<$sec_name>\"" "$HOME/${GIT_REPO_NAME}/.env")" = "\"<$sec_name>\"" ]]; do
                    if sed -i 's|"<'"$sec_name"'>"|'"$sec_value"'|' "$HOME/${GIT_REPO_NAME}/.env"; then
                        # This because it seems, if we act to soon it doesn't write.
                        sync "$HOME/${GIT_REPO_NAME}/.env"
                        # Sleep for 1 second
                        sleep 0.2
                    fi
                done
            fi
        fi
    done <"$HOME/.${GIT_REPO_NAME}"

    # Replace deployment variables
    while grep -F "\"<DEPLOYMENT_VERSION>\"" "$HOME/${GIT_REPO_NAME}/.env" &>/dev/null; do
        sed -i "s|\"<DEPLOYMENT_VERSION>\"|$LATEST_PROJECT_SHA|" "$HOME/${GIT_REPO_NAME}/.env"
        sync "$HOME/${GIT_REPO_NAME}/.env"
        sleep 0.2s
    done
    sed -i "s|\"<DEPLOYMENT_AT>\"|$NOWDATESTAMP|" "$HOME/${GIT_REPO_NAME}/.env"

    # Call sync on .env file for inode changes
    sync "$HOME/${GIT_REPO_NAME}/.env"

    # _log_info "END: Replacing APP environment variables"
}

# Function: _get_project_docker_compose_file
# Description: Locates projects docker compose file.
# Parameters: None
# Returns:
#   0 if failed to locate docker-compose yml file
#   File path to project docker compose file

_get_project_docker_compose_file() {
    local docker_compose_file="0"

    # Check if docker-compose is installed
    if [[ "$(_is_present docker-compose)" = "1" ]]; then

        # Check for the default docker-compose yml file
        if [[ -f "$HOME/${GIT_REPO_NAME}/docker-compose.yml" ]]; then
            docker_compose_file="$HOME/${GIT_REPO_NAME}/docker-compose.yml"
        fi
        # Check for docker compose file with deployment environment tag
        if [[ -f "$HOME/${GIT_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml" ]]; then
            docker_compose_file="$HOME/${GIT_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml"
        fi
    fi

    # Return results
    echo "${docker_compose_file}"
}

# Function: _start_project
# Description: Start project.
# Parameters: None
# Returns: None

_start_project() {
    local docker_compose_file="0"

    # Generic docker compose up
    if [[ "$(_is_present docker-compose)" = "1" ]]; then

        cd "$HOME/${GIT_REPO_NAME}" || _exit_script

        docker_compose_file="$(_get_project_docker_compose_file)"

        # Start running deployment
        if [[ "${docker_compose_file}" != "0" ]]; then

            local screen_name="${GIT_REPO_NAME}_start_project"
            ## IF SCREEN PROGRAM IS INSTALL
            if [[ "$(_is_present screen)" = "1" ]]; then

                ## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
                if ! screen -list | grep -q "${screen_name}"; then

                    screen -dmS "${screen_name}"
                    screen -S "${screen_name}" -p 0 -X stuff 'cd '"$HOME"'/'"${GIT_REPO_NAME}"' \n'
                    screen -S "${screen_name}" -p 0 -X stuff 'docker-compose -f '"${docker_compose_file}"' up -d; exit\n'

                else # IF SCREEN FOUND

                    _log_error "Already attempting to start project."
                fi

                sleep 1s
                while screen -list | grep -q "${screen_name}"; do
                    sleep 1s
                done
            else ## IF NO SCREEN PROGRAM

                docker-compose -f "${docker_compose_file}" up -d
            fi

            _log_info "Started docker containers"

        fi
    fi
}

# Function: _stop_project
# Description: Stop project.
# Parameters: None
# Returns: None

_stop_project() {
    local docker_compose_file="0"

    # Generic docker compose down
    if [[ "$(_is_present docker-compose)" = "1" ]]; then

        cd "$HOME/${GIT_REPO_NAME}" || _exit_script

        docker_compose_file="$(_get_project_docker_compose_file)"

        # Stop running deployment
        if [[ "${docker_compose_file}" != "0" ]]; then

            local screen_name="${GIT_REPO_NAME}_stop_project"
            ## IF SCREEN PROGRAM IS INSTALL
            if [[ "$(_is_present screen)" = "1" ]]; then

                ## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
                if ! screen -list | grep -q "${screen_name}"; then

                    screen -dmS "${screen_name}"
                    screen -S "${screen_name}" -p 0 -X stuff 'cd '"$HOME"'/'"${GIT_REPO_NAME}"' \n'
                    screen -S "${screen_name}" -p 0 -X stuff 'docker-compose -f '"${docker_compose_file}"' down; exit\n'

                else # IF SCREEN FOUND

                    _log_error "Already attempting to stop project."
                fi

                sleep 1s
                while screen -list | grep -q "${screen_name}"; do
                    sleep 1s
                done
            else ## IF NO SCREEN PROGRAM

                docker-compose -f "${docker_compose_file}" down
            fi

            _log_info "Stopped docker containers"
        fi
    fi
}

# END - PROJECT FUNCTIONS

# START - UPDATE CRONJOB

# Function: _install_update_cron
# Description: Sets up the update project cronjob.
# Parameters: None
# Returns: None

_install_update_cron() {
    # shellcheck disable=SC2005
    echo "$(_install_cronjob "*/15 * * * *" "/bin/bash $HOME/${GIT_REPO_NAME}/${SCRIPT} version:check")"
}

# Function: _remove_update_cron
# Description: Removes  the update project cronjob.
# Parameters: None
# Returns: None

_remove_update_cron() {
    # shellcheck disable=SC2005
    echo "$(_remove_cronjob "*/15 * * * *" "/bin/bash $HOME/${GIT_REPO_NAME}/${SCRIPT} version:check")"
}

# END - UPDATE CRONJOB

# START - GIT SERVICES

# Function: _git_service_provider
# Description: Returns git service providers domain.
# Parameters: None
# Returns: None

_git_service_provider() {
    # shellcheck disable=SC2164
    cd "$HOME"/"${GIT_REPO_NAME}"
    local git_domain

    git_domain=$(git remote get-url origin | awk -F'@|:' '{gsub("//", "", $2); print $2}')
    echo "$git_domain"
}

# END - GIT SERVICES

# START - GITHUB TOKEN

# Function: _check_github_token
# Description: Check $GITHUB_TOKEN variable has been set and matches the github personal token pattern.
# Parameters: None
# Returns:
#   1 if successfully loaded github token and matches pattern

_check_github_token() {
    local pattern="^ghp_[a-zA-Z0-9]{36}$"
    [[ ${GITHUB_TOKEN:-"ghp_##"} =~ $pattern ]] && echo 1
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
    # Call _check_github_token to vildate current token variable.
    if [[ $(_check_github_token) = "1" ]]; then
        return
    fi

    # Call function to check for token file
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
    local pattern="^ghp_[a-zA-Z0-9]{36}$"
    local token

    # If function has param
    if [[ $# -ge 1 ]]; then
        # Use the param $1 as token
        token=$1
    elif [[ "$(_interactive_shell)" = "1" ]]; then # If run from tty

        # Create user interaction to get token from user.
        read -rp "Please provide Github personal access token (empty: cancel): " input_token

        token="$input_token"

        # Check user input token against pattern above.
        if [[ ! $token =~ $pattern ]]; then
            # Log error and exit script
            # _log_error "Missing github token file .github_token"
            _log_error "GITHUB_TOKEN=ghp_azAZ09azAZ09azAZ09azAZ09azAZ09azAZ09"
            _log_error "public_repo, read:packages, repo:status, repo_deployment"
            _log_error "Invalid github personal access token."
            _exit_script
        fi
    fi

    # If give token matches pattern
    if [[ $token =~ $pattern ]]; then
        # Create github token file
        echo "#" >"$HOME"/.github_token
        echo "GITHUB_TOKEN=$token" >>"$HOME"/.github_token
        echo "" >>"$HOME"/.github_token
        chmod 700 "$HOME"/.github_token
        # Load github token
        _load_github_token
        # Return success
        echo 1
    else
        # Log error and exit script
        _log_error "Invalid github personal access token."
        _exit_script
    fi
}

# END - GITHUB TOKEN

# START - GITHUB API

# Function: _get_project_github_latest_sha
# Description: Gets project files latest git commit sha from github.
# Parameters: None
# Returns:
#   0 - if failed to get latest git commit sha
#   github commit sha

_get_project_github_latest_sha() {

    # Load the github token if not loaded
    _load_github_token

    # Validate loaded token
    if [[ "$(_check_github_token)" = "0" ]]; then
        # On fail ask user to create token
        _write_github_token
    fi

    # Create local function variable
    local curl_data gh_sha

    # Send request to github with creds
    curl_data=$(curl -s -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version:2022-11-28" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$GITHUB_REPO_URL")

    # Check returned data from request
    if [[ $(echo "$curl_data" | jq -r .message 2>/dev/null && echo 1) ]]; then
        # Log error and return fail from function
        _log_to_file "$(echo "$curl_data" | jq .message)"
        echo 0
        return
    fi

    # Validate commit sha and return.
    if [[ $(echo "$curl_data" | jq -r .[0].commit.tree.sha 2>/dev/null && echo 1) ]]; then
        gh_sha="$(echo "$curl_data" | jq .[0].commit.tree.sha)"
        echo "${gh_sha//\"/}"
        return
    fi

    # Return fail code.
    echo 0
}

# END - GITHUB API

# START - ONEDEV TOKEN

# Function: _check_onedev_token
# Description: Check $GITHUB_TOKEN variable has been set and matches the onedev personal token pattern.
# Parameters: None
# Returns:
#   1 if successfully loaded github token and matches pattern

_check_onedev_token() {
    local pattern="^[A-Za-z0-9]+$"
    [[ ${ONEDEV_TOKEN:-"######"} =~ $pattern ]] && echo 1
}

# Function: _check_onedev_file
# Description: Check the location for the onedev token file.
# Parameters: None
# Returns:
#   1 if github token file exists, otherwise 0.

_check_onedev_file() {
    [[ -f "$HOME/.onedev_auth" ]] && echo 1
}

# Function: _load_onedev_token
# Description: If onedev token already has been loaded or check and loads from file then validate.
# Parameters: None
# Returns:
#   1 if github token already loaded or loads token from file and matches pattern, otherwise 0.

_load_onedev_token() {
    if [[ $(_check_onedev_token) = "1" ]]; then
        return
    fi

    if [[ "$(_check_onedev_file)" = "1" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.onedev_auth" || echo "Failed import of onedev_auth"
    fi
}

# Function: _write_onedev_token
# Description: Given a onedev token or from user prompt, validate and creates .onedev_token file.
# Parameters:
#   $1: optional github token
# Returns:
#   1 if successfully installed github token.

# shellcheck disable=SC2120
_write_onedev_token() {
    # Set local function variables
    local pattern="^[A-Za-z0-9]+$"
    local token username

    # If function has been given 1 argument
    if [[ $# -ge 1 ]]; then
        # Use the param $1 as token
        token=$1
    elif [[ "$(_interactive_shell)" = "1" ]]; then # If run from tty

        # Create user interaction to get token from user.
        read -rp "Please provide OneDev Access Token (empty: cancel): " input_token

        token="$input_token"

        # Check user input token against pattern above.
        if [[ ! $token =~ $pattern ]]; then
            # Log error and exit script
            # _log_error "Missing github token file .onedev_auth"
            _log_error "ONEDEV_TOKEN=########"
            _log_error "ONEDEV_USERNAME=######"
            _exit_script
        fi
    fi

    # If give token matches pattern
    if [[ $token =~ $pattern ]]; then

        # Write token file
        echo "#" >"$HOME"/.onedev_auth
        echo "ONEDEV_TOKEN=$token" >>"$HOME"/.onedev_auth

        # If function has been given 2 arguments
        if [[ $# -ge 2 ]]; then
            username="$2"
        else
            # Create user interaction to get username from user.
            read -rp "Please provide OneDev Username (empty: cancel): " input_username
            username="$input_username"
        fi

        # Add username variable to token file
        echo "ONEDEV_USERNAME=$username" >>"$HOME"/.onedev_auth

        echo "" >>"$HOME"/.onedev_auth
        chmod 700 "$HOME"/.onedev_auth

        # Load token from newly create token file
        _load_onedev_token
        echo 1
    else
        # Log error and exit script
        _log_error "Invalid github personal access token."
        _exit_script
    fi
}

# END - GITHUB TOKEN

# START - ONEDEV API

# Function: _get_project_onedev_latest_sha
# Description: Gets project files latest git commit sha from onedev.
# Parameters: None
# Returns:
#   0 - if failed to get latest git commit sha
#   github commit sha

_get_project_onedev_latest_sha() {
    # Call function to load token if not loaded
    _load_onedev_token

    # Run check on token variable
    if [[ "$(_check_onedev_token)" != "1" ]]; then
        # Ask user to full missing token
        _write_onedev_token
    fi

    # Set local function variables
    local curl_data project_id onedev_sha

    cd "$HOME"/"${GIT_REPO_NAME}" || _exit_script
    local git_domain git_url

    # Calling _git_service_provider function to check git provider from .git data
    git_url=$(git remote get-url origin)
    git_domain="$(_git_service_provider)"

    # URL to process
    local query='query="Name" is "'${GIT_REPO_NAME}'"'

    cleaned_url="${git_url#*://}"                  # Remove "http://" or "https://"
    cleaned_url="${cleaned_url#*/*}"               # Remove "git.xoren.io:6611/"
    cleaned_url="${cleaned_url/\/$GIT_REPO_NAME/}" # Remove "git.xoren.io"

    if [[ ${#cleaned_url} -ge 1 ]]; then
        query+=' and children of "'${cleaned_url}'"'
    fi
    ## Enable for debugging.
    # _log_to_file "query: $query"

    # Send request to git api to get id of repo
    curl_data=$(curl -s -u "${ONEDEV_USERNAME}:${ONEDEV_TOKEN}" \
        -G https://git.xoren.io/~api/projects \
        --data-urlencode "${query}" \
        --data-urlencode offset=0 --data-urlencode count=100)

    # Check request returning data
    if [[ ! $(echo "$curl_data" | jq .[0].id 2>/dev/null && echo 1) ]]; then
        # Error in api response, log and return fail from this function.
        _log_to_file "Cant find project id from git api"
        echo 0
        return
    fi

    # Set if from request data
    project_id="$(echo "$curl_data" | jq .[0].id)"

    # Send request to git repo api for commit data
    curl_data=$(curl -s -u "${ONEDEV_USERNAME}:${ONEDEV_TOKEN}" \
        -G "https://git.xoren.io/~api/repositories/${project_id}/commits" \
        --data-urlencode count=1)

    # Check request returning data
    if [[ $(echo "$curl_data" | jq -r .[0] 2>/dev/null && echo 1) ]]; then

        # On success echo back sha
        onedev_sha="$(echo "$curl_data" | jq .[0])"
        echo "${onedev_sha//\"/}"
        return
    fi

    # Return error code if failed above check.
    echo 0
}

# END - ONEDEV API

# START - UPDATE FUNCTIONS

# Function: _download_project_files
# Description: Performs re-download of the project files by cloning a fresh copy via git  and updating project files.
#              It also moves the old project folder to a backup location.
#              The function replaces environment variables and propagates the environment file.
# Parameters: None
# Returns: None

_download_project_files() {

    cd "$HOME"/"${GIT_REPO_NAME}" || _exit_script

    GIT_URL=$(git remote get-url origin)

    # Leave project folder.
    cd "$HOME" || _exit_script

    # Log the folder move.
    _log_to_file "Moving old project folder."

    # Delete old environment secret.
    [[ -f "$HOME/${GIT_REPO_NAME}/.env" ]] && rm "$HOME/${GIT_REPO_NAME}/.env"

    # Remove old project directory.
    mv -u -f "$HOME/$GIT_REPO_NAME" "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}"

    # Call inode sync.
    sync "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}"

    # Run git clone in if to error check.
    if ! git clone --quiet "${GIT_URL}"; then # If failed to git clone

        # Move old project files back to latest directory
        mv -u -f "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}" "$HOME/$GIT_REPO_NAME"

        # Log the error
        _log_error "Cant contact to $(_git_service_provider)"

        # Call function to start project
        _start_project
    fi

    # Call inode sync
    sync "$HOME/${GIT_REPO_NAME}"
}

# Function: _update
# Description: Performs re-deployment of the project by cloning a fresh copy from GitHub and updating project files.
#              It also moves the old project folder to a backup location.
#              The function replaces environment variables and propagates the environment file.
# Parameters: None
# Returns: None

_update() {

    # Set local variable.
    local docker_compose_file="0"

    cd "$HOME/$GIT_REPO_NAME" || _exit_script

    # Set local variable using _get_project_docker_compose_file function
    docker_compose_file="$(_get_project_docker_compose_file)"

    # Check for _update.sh script to overwrite or provide update functions
    if [[ -f "$HOME/${GIT_REPO_NAME}/_update.sh" ]]; then

        # shellcheck disable=SC1090
        source "$HOME/${GIT_REPO_NAME}/_update.sh"

        # if [[ ! -n "$(type -t _pre_update)" && ! -n "$(type -t _post_update)"  ]]; then
        #     return
        # fi
    fi

    # Log the re-deployment
    _log_to_file "Re-deployment Started"
    _log_to_file "====================="
    _log_to_file "env: ${DEPLOYMENT_ENV}"

    # Enter project repo
    cd "$HOME/$GIT_REPO_NAME" || _exit_script

    # Check if the function is set
    if [[ -n "$(type -t _pre_update)" ]]; then
        _pre_update
    else
        # Run function to stop services.
        _stop_project

        # Check for docker-comspose with file
        if [[ "$DOCKER_IS_PRESENT" = "1" && "${docker_compose_file}" != "0" ]]; then
            # Remove deployment docker images
            _log_info "Removing docker images"
            yes | docker-compose -f "${docker_compose_file}" rm

            # Remove images using yq to read docker file
            if [[ "$(_is_present yq)" = "1" ]]; then
                yq '.services[].container_name' "${docker_compose_file}" |
                    while IFS= read -r container_name; do
                        yes | docker image rm "${container_name//\"/}"
                    done
            fi
        fi
    fi

    # Leave project directory
    cd "$HOME" || _exit_script

    # Call function to download fresh copy of project
    _download_project_files

    # Move any log or json files
    if ls "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/"*.log 1>/dev/null 2>&1; then
        mv "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/"*.log "$HOME/${GIT_REPO_NAME}/"
    fi
    if ls "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/"*.json 1>/dev/null 2>&1; then
        mv "$HOME/${GIT_REPO_NAME}_${NOWDATESTAMP}/"*.json "$HOME/${GIT_REPO_NAME}/"
    fi

    # Log the download finishing
    _log_to_file "Finished cloning fresh copy from ${GITHUB_REPO_OWNER}/${GIT_REPO_NAME}."

    # Replace .env file
    _replace_env_project_secrets

    # Check if _post_update function has been set
    if [[ -n "$(type -t _post_update)" ]]; then
        _post_update
    else
        # If no _post_update function
        if [[ "$DOCKER_IS_PRESENT" = "1" && "${docker_compose_file}" != "0" ]]; then
            docker-compose -f "${docker_compose_file}" up -d --build
        fi

        # Call function to delete old project files if condition match
        _delete_old_project_files
    fi

    # Log the finishing of the update
    _log_to_file "Finished updated project files."
    _log_to_file ""
}

# Function: _set_latest_sha
# Description: Checks git repo provider and gets sha from provider api.
# Parameters: None
#   $1: (optional) echo SHA
# Returns: None
#    SHA: if

_set_latest_sha() {
    cd "$HOME"/"${GIT_REPO_NAME}" || _exit_script
    local git_domain

    # Calling _git_service_provider function to check git provider from .git data
    git_domain="$(_git_service_provider)"

    # Check git provider host again known list
    if echo "$git_domain" | grep -q github.com; then
        # Set LATEST_PROJECT_SHA from github api function
        LATEST_PROJECT_SHA="$(_get_project_github_latest_sha)"
        if [[ $# -ge 1 ]]; then
            echo "$LATEST_PROJECT_SHA"
        fi
        return
    elif [[ "$git_domain" = "git.xoren.io" ]]; then
        # Set LATEST_PROJECT_SHA from onedev api function
        LATEST_PROJECT_SHA="$(_get_project_onedev_latest_sha)"
        if [[ $# -ge 1 ]]; then
            echo "$LATEST_PROJECT_SHA"
        fi
        return
    else
        if [[ $# -ge 1 ]]; then
            echo 0
            return
        fi
        # Unknown or no provider
        _log_error "Cant find git host."
        _exit_script
    fi
}

# Function: _check_latest_sha
# Description: Sets LATEST_PROJECT_SHA via _set_latest_sha function, if LATEST_PROJECT_SHA not already set.
# Parameters: None
# Returns: None

_check_latest_sha() {
    local sha_length

    # Check if LATEST_PROJECT_SHA isn't set
    if [[ -z "${LATEST_PROJECT_SHA}" ]]; then
        # Call function to set LATEST_PROJECT_SHA
        LATEST_PROJECT_SHA="$(_set_latest_sha true)"
    else
        # If LATEST_PROJECT_SHA is set check length
        sha_length=${#LATEST_PROJECT_SHA}
        if ((sha_length <= 31)); then
            # If LATEST_PROJECT_SHA length is smaller then 32
            LATEST_PROJECT_SHA="$(_set_latest_sha true)"
        fi
    fi
}

# Function: _check_update
# Description: Checks if the local version matches the remote version of the repository.
# If the versions match, the script will exit.
# If the versions do not match, the script will perform an update and update the local version.
# Parameters: None
# Returns: None

_check_update() {

    if [[ "$(_check_working_schedule)" = "1" ]]; then
        _exit_script
    fi

    # Call function to set if not set latest project sha.
    _check_latest_sha
    # LATEST_PROJECT_SHA="$(_check_latest_sha true)"

    # If LATEST_PROJECT_SHA equals 0.
    if [[ "${LATEST_PROJECT_SHA}" = "0" ]]; then
        # Log error and exit scripts
        _log_error "Failed to fetching SHA from git api service"
        _exit_script
    fi
    # If LATEST_PROJECT_SHA is blank.
    if [[ "${LATEST_PROJECT_SHA}" = "" ]]; then
        # Log error and exit scripts
        _log_error "Failed to fetching SHA from git api service"
        _exit_script
    fi

    # Check for default value.
    if [[ "${DEPLOYMENT_VERSION}" = "<DEPLOYMENT_VERSION>" ]]; then

        # Replace with requested data version.
        _log_error "Current version <DEPLOYMENT_VERSION> AKA deployment failure somewhere"
        _update
    elif [[ "${DEPLOYMENT_VERSION}" = "DEV" ]]; then

        _log_error "Updating is disabled in development"
    else

        # If local version and remote version match.
        if [[ "${DEPLOYMENT_VERSION}" = "${LATEST_PROJECT_SHA}" ]]; then

            if [[ "$(_interactive_shell)" = "1" ]]; then
                _log_info "VERSION MATCH, ending script"
            fi
            _exit_script
        fi

        # Finally run the update function
        _update
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

    _install_update_cron
}

# END -SETUP
