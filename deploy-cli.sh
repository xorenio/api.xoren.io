#!/bin/bash

# Author: admin@xoren.io
# Script: deploy-cli.sh
# Link https://github.com/xorenio
# Description: Script to manage the last mile deployment.

# START - Script setup and configs

NOWDATESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
SCRIPT_NAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed 's/\.[^.]*$//')
SCRIPT=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR_NAME="$(basename "$PWD")"
SCRIPT_DEBUG=false # true AKA echo to console | false echo to log file
SCRIPT_CMD_ARG=("${@:1}")  # Assign command line arguments to array
FUNCTION_ARG=("${@:2}")  # Assign command line arguments to array

STARTING_LOCATION="$(pwd)"
cd "$SCRIPT_DIR" || exit

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
if [[ "$(_interactive_shell)" = "1" ]]; then
    if [ "$APT_IS_PRESENT" ]; then
        export DEBIAN_FRONTEND=noninteractive
    fi
    SCRIPT_DEBUG=false
else
    SCRIPT_DEBUG=true
fi

if [[ "$CURL_IS_PRESENT" != "1" ]]; then
    _log_error "Please install curl."
    exit
fi

if [[ "$WHOIS_IS_PRESENT" != "1" ]]; then
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

## CHECK FOR PROJECT VAR FILE
_check_project_secrets


## SET DEPLOY ENV VAR TO LOCATION
if [[ "$DEPLOYMENT_ENV_LOCATION" = "true" ]]; then
    _set_location_var
    DEPLOYMENT_ENV="$ISOLOCATION"
fi

## CHECK .env FILE
if [[ ! -f "$HOME"/"${GITHUB_REPO_NAME}"/.env ]]; then

    cp "$HOME"/"${GITHUB_REPO_NAME}"/.env."${DEPLOYMENT_ENV}" "$HOME"/"${GITHUB_REPO_NAME}"/.env
fi

## LOAD .env VARS
# shellcheck disable=SC1090
source "$HOME"/"${GITHUB_REPO_NAME}"/.env

## SECRETS
_load_project_secrets

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
            _log_info "\/ Manually started re-install \/"
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
            _log_info "Local version: $DEPLOYMENT_VERSION"
            ;;
        "version:remote")
            _log_info "Github version: $(_get_project_github_latest_sha)"
            ;;
        "write:github:token")
            if [[ ${#SCRIPT_CMD_ARG} -ge 2 ]]; then
                _write_github_token "${FUNCTION_ARG[@]}"
            else
                _write_github_token
            fi
            ;;
    esac
else
    if [[ "$(_interactive_shell)" = "0" ]]; then
        _log_error "Headless mode not setup."
    else
        cat <<EOF
USAGE: ${SCRIPT} [option]

Options:

repo:check                                  Check deployment updates.
repo:update                                 Manually start an update.

setup                                       All setup steps and install:deps also update cron.
setup:git:profile                           Set up git name and email.
setup:secrets                               Create secrets file outside of repo folder.
setup:ssh:keys                              Add SSH keys from .env file.

version:local                               Print the local version of this repo.
version:remote                              Print the local and remote versions of the repo.

write:github:token                          To setup the local GitHub token.

EOF
    fi
fi

_delete_running_file

# END - SCRIPT RUNTIME