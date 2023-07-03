#!/bin/bash

#
# @author admin@xoren.io
# @description Script to setup a kvm for hosting
# @link https://github.com/xorenio
#




# START - Script setup and configs

NOWDATESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
SCRIPT_NAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed 's/\.[^.]*$//')
SCRIPT=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR_NAME="$(basename $PWD)"
SCRIPT_DEBUG=false # true AKA echo to console | false echo to log file
SCRIPT_CMD_ARG=("${@:1}")  # Assign command line arguments to array

cd $SCRIPT_DIR

DEPLOYMENT_ENV_LOCATION=false
DEPLOYMENT_ENV="production"
ISOLOCATION="GB" ## DEFAULT US
ISOSTATELOCATION="" ## DEFAULT EMPTY

## DEFINE REPO
GITHUB_REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com:\([^/]*\)\/.*/\1/p')
GITHUB_REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
GITHUB_REPO_URL="https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/commits"

SCRIPT_LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"
JSON_FILE_NAME="${SCRIPT_DIR}/${SCRIPT_NAME}_${NOWDATESTAMP}.json"
SCRIPT_RUNNING_FILE="$HOME/${GITHUB_REPO_NAME}_running.txt"

# END - Script setup and configs




# START - IMPORT FUNCTIONS

source "$SCRIPT_DIR/_functions.sh"

# END - IMPORT FUNCTIONS




# START - SCRIPT PRE-CONFIGURE

## SET LOGGING TO TTY OR TO deployment.log
if [[ "$(_interactive_shell)" = "true" ]]; then
    if [ "$APT_IS_PRESENT" ]; then
        export DEBIAN_FRONTEND=noninteractive
    fi
    SCRIPT_DEBUG=false
else
    SCRIPT_DEBUG=true
fi

if [[ "$CURL_IS_PRESENT" = "false" ]]; then
    _log_error "Please install curl."
    exit
fi

if [[ "$WHOIS_IS_PRESENT" = "false" ]]; then
    _log_error "Please install whois."
    exit
fi

## CHECK IF SCRIPT IS ALREADY RUNNING
_check_running_file

## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
# if [[ $SCREEN_IS_PRESENT == true ]]; then

    # _log_info "Script screen check."
    # if screen -list | grep -q "${SCRIPT_DIR_NAME}_deployment"; then
    #     _log_error "${SCRIPT_DIR_NAME}_deployment screen still running."
    #     exit;
    # fi
# fi

## ECHO STARTTIME TO DEPLOYMENT LOG FILE
_create_running_file

## ENTER PROJECT DIRECTORY
cd "$SCRIPT_DIR"

## CHECK FOR PROJECT VAR FILE
_check_secrets_file


## SET DEPLOY ENV VAR TO LOCATION
if [[ "$DEPLOYMENT_ENV_LOCATION" = "true" ]]; then
    _set_location_var
    DEPLOYMENT_ENV="$ISOLOCATION"
fi

## CHECK .env FILE
if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then

    cp "${SCRIPT_DIR}/.env.${DEPLOYMENT_ENV}" "$SCRIPT_DIR/${GITHUB_REPO_NAME}/.env"
fi

## LOAD .env VARS and GITHUB TOKEN AND SECRETS
# _log_info "Loading .env & github var"
source "${SCRIPT_DIR}/.env"
## SECRETS
_load_secrets_file

# END - SCRIPT PRE-CONFIGURE



# START - SCRIPT RUNTIME

## Command line argument
if [[ ${#SCRIPT_CMD_ARG} -ge 1 ]]; then
    case "${SCRIPT_CMD_ARG[0]}" in
        "queue:worker")
            _process_queue
            ;;
        "repo:check")
            _check_update
            ;;
        "repo:update")
            _log_info ""
            _log_info "================================="
            _log_info "\/ Manually re-install started \/"
            _log_info "================================="
            _update
            ;;
        "setup")
            _setup
            ;;
        "setup:git:profile")
            _setup_git
            ;;
        "setup:ssh:keys")
            _setup_ssh_key
            ;;
        "setup:secrets")
            _write_secrets_file
            ;;
        "version:local")
            _log_info "Local version: $APP_VERSION"
            ;;
        "version:remote")
            _get_project_remote_version
            ;;
    esac

else
    if [[ "$(_interactive_shell)" = "0" ]]; then
        _log_error "Headless mode not setup."
    else
        _log_console "=== Missing Command Line Argument ==="
        _log_console ""

        _log_console "repo:check"
        _log_console "    - Check local repo version against remote and update if necessary."
        _log_console "repo:update"
        _log_console "    - Manually start an update of local repo files."

        _log_console "setup"
        _log_console "    - Do all the setup steps and install update cron."

        _log_console "setup:git:profile"
        _log_console "    - Set up git name and email."

        _log_console "setup:ssh:keys"
        _log_console "    - Add xorenio SSH keys from GitHub."
        _log_console "setup:secrets"
        _log_console "    - Create secrets file outside of repo folder."

        _log_console "version:local"
        _log_console "    - Print the local version of this repo."
        _log_console "version:remote"
        _log_console "    - Print the local and remote versions of the repo."
    fi
fi


_delete_running_file

# END - SCRIPT RUNTIME