#!/bin/bash

## author me@xoren.io
## For internal server auto deployment from github repo
## https://docs.github.com/en/rest/packages










## START - Script setup and configs
#
#
#
#

## DEFINE SCRIPT VAR AND HELPER FUNCTION
NOWDATESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
SCRIPT="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
SCRIPT_DEBUG=false # true AKA echo to console | false echo to log file

cd $SCRIPT_DIR

DEPLOYMENT_ENV_LOCATION=false
DEPLOYMENT_ENV="production"
ISOLOCATION="GB" ## DEFAULT US


## DEFINE REPO
GITHUB_REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com:\([^/]*\)\/.*/\1/p')

GITHUB_REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
GITHUB_REPO_URL="https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/commits"


GITHUB_REPO_PACKAGE_CHECK=false
GITHUB_REPO_PACKAGE_NAME="xoren-io-api"
GITHUB_REPO_PACKAGE_URL=https://api.github.com/orgs/$GITHUB_REPO_OWNER/packages/container/$GITHUB_PACKAGE_NAME

#
#
#
#
## START - Script setup and configs










## START - SCRIPT FUNCTIONS
#
#
#
#

## LOG FUNCTIONS
logError() {
    logData "ERROR" "$1"
}


logInfo() {
    logData "INFO" "$1"
}


logDebug() {
    logData "DEBUG" "$1"
}


logSuccess() {
    logData "✓" "$1"
}


logData() {
    if [[ $# -eq 2 ]]; then
        STR="[$NOWDATESTAMP][$1] $2"
    else
        STR="[$NOWDATESTAMP] $1"
    fi

    if [[ $SCRIPT_DEBUG == true ]]; then
        logConsole "$STR"
    fi

    logToFile "$STR"
    return;
}


logToFile() {
    if [[ ! -f ~/deployment.log ]]; then
        echo $1  > ~/deployment.log
        return
    fi
    echo $1 >> ~/deployment.log
}


logConsole() {
     echo $1
}



## DEFINE HELPER FUNCTIONS
function isPresent { command -v "$1" &> /dev/null && echo 1; }
function isFileOpen { lsof "$1" &> /dev/null && echo 1; }
function isCron { [ -z "$TERM" ] || [ "$TERM" = "dumb" ] && echo 1; }
# [ -z "$TERM" ] || [ "$TERM" = "dumb" ] && echo 'Crontab' || echo 'Interactive'



## DEFINE HELPER VARS
SCREEN_IS_PRESENT="$(isPresent screen)"
JQ_IS_PRESENT="$(isPresent jq)"
WHOIS_IS_PRESENT="$(isPresent whois)"
CURL_IS_PRESENT="$(isPresent curl)"



## LOCATION FUNCTIONS
## ARGE #1 $IP ADDRESS
## EXMAPLE: $ echo valid_ip 192.168.1.1
function valid_ip() {

    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


function set_location_var() {

    ## GET PUBLIC IP
    ip=$(curl -s -X GET https://checkip.amazonaws.com)

    ## VAILDATE AND COPY ENV FILE
    if valid_ip ${ip}; then

        ISOLOCATION=$(whois $ip | grep -iE ^country:)
        ISOLOCATION=$( echo $ISOLOCATION | head -n 1 )
        ISOLOCATION=${ISOLOCATION:(-2)}
    fi
}



function writeEnvVars() {

     cat > ~/.${GITHUB_REPO_NAME} <<EOF
# This file requests two lines or its doesnt read
APP_KEY=base64:
APP_USER_UUID=1000
APP_USER=laravel
DB_HOST=localhost
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="password"
EOF
     logInfo "Writen env vars file ~/.${GITHUB_REPO_NAME}"
}


function replaceEnvVars() {

    logInfo "START: Replacing APP environment variables"


    ## CHECK IF FILE DOESNT EXIST AND CREATE IT
    if [[ ! -f ~/.${GITHUB_REPO_NAME} ]]; then
        writeEnvVars
    fi


    ## READ EACH LINE OF CONFIG FILE
    while read CONFIGLINE
    do
        ## GET FOR CHECK FIRST CHAR IN CONFIG LINE
        LINEF=${CONFIGLINE:0:1}

        ## CHECK FIRST LETTER ISN'T # & LINE LETTER LENGTH IS LONGER THEN 3
        if [[ $LINEF != " " && $LINEF != "#" && ${#CONFIGLINE} > 3 ]]; then

            ## CHECK FOR = IN CONFIG LINE SEPERATE IF STATMENT FORMATTED DIFFERENTLY TO WORK
            if echo $CONFIGLINE | grep -F = &>/dev/null; then
                CONFIGNAME=$(echo "$CONFIGLINE" | cut -d '=' -f 1)
                CONFIGVALUE=$(echo "$CONFIGLINE" | cut -d '=' -f 2-)
                # echo "CONFIGNAME: $CONFIGNAME"
                # echo "CONFIGVALUE: $CONFIGVALUE"
                # cat .env.production | grep "<$CONFIGNAME>"

                if cat .env.${DEPLOYMENT_ENV} | grep '"<'$CONFIGNAME'>"' &>/dev/null; then
                     sed -i 's|"<'$CONFIGNAME'>"|'$CONFIGVALUE'|' .env.${DEPLOYMENT_ENV}
                fi
            fi
        fi
    done < ~/.${GITHUB_REPO_NAME}


    ## REPLACED DEPLOYMENT VARS
    sed -i 's|"<APP_VERSION>"|'$NEW_VERSION'|' .env.${DEPLOYMENT_ENV}
    sed -i 's|"<APP_UPDATED_AT>"|'$NOWDATESTAMP'|' .env.${DEPLOYMENT_ENV}


    logInfo "END: Replacing APP environment variables"
}



## PROJECT UPDATE CHECKS FUNCTIONS
function getProjectRemoteVersion() {

    logInfo "Getting remote version"

    if [[ $GITHUB_REPO_PACKAGE_CHECK == true ]]; then

        getProjectVersionViaRepoPackage
    else

        getProjectVersionViaRepo
    fi


    logInfo "Local version: $APP_VERSION"
    logInfo "Github version: $NEW_VERSION"
}


function getProjectVersionViaRepo() {

    ## SEND REQUEST TO GITHUB FOR REPOSOTORY REPO DATA
    logInfo "Sending request to github API for package data"


    DATA=$( curl -s -H "Accept: application/vnd.github+json" \
        -H "Authorization: token $GITHUB_TOKEN" \
        $GITHUB_REPO_URL)


    NEW_VERSION=$(echo $DATA | jq .[0].commit.tree.sha)
}


function getProjectVersionViaRepoPackage() {

    ## SEND REQUEST TO GITHUB FOR REPO PACKAGE DATA
    logInfo "Sending request to github API for package data"


    DATA=$( curl -s -H "Accept: application/vnd.github+json" \
        -H "Authorization: token $GITHUB_TOKEN" \
        $GITHUB_REPO_PACKAGE_URL)


    NEW_VERSION=$(echo $DATA | jq -r .version_count)
}




## DOING UPDATE FUNCTION
function doUpdate() {

    logInfo ""
    logInfo "Re-deployment Started"
    logInfo "====================="
    logInfo "env: ${DEPLOYMENT_ENV}"



    ## ENTER PROJECT REPO DIRECTORY
    cd ~/$GITHUB_REPO_NAME/



    ## STOP DOCKER APP
    logInfo "Stopping docker containers"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml down
    else
        docker-compose down
    fi



    ## DELETE PROJECT DOCKER IMAGES
    logInfo "Removing old docker images"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        yes | docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml rm #--all # dep
    else
        yes | docker-compose rm #--all # dep
    fi



    ## REMOVE DOCKER IMAGES VIA NAME
    yes | docker image rm xoren-io-laravel
    yes | docker image rm xoren-io-nginx
    yes | docker image rm xoren-io-websocket
    # yes | docker-compose -f docker-compose.prod.yml rm



    ## LEAVE PROJECT DIRECTORY
    cd ~/



    ## RENAME OLD PROJECT DIRECTORY
    logInfo "mv project folder to somewhere with a timestamp"
    mv -u -f ~/$GITHUB_REPO_NAME/ ~/${GITHUB_REPO_NAME}_${NOWDATESTAMP}



    ## FIX FOR INODE CHANGES
    logInfo "Inode sync"
    sync
    sleep 2s



    ## CLONE FRESH COPY OF PROJECT
    logInfo "Cloned fresh copy from github $GITHUB_REPO_OWNER/${GITHUB_REPO_NAME}"
    git clone git@github.com:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git



    ## FIX FOR INODE CHANGES
    logInfo "Inode sync"
    sync
    sleep 2s



    ## MOVE PROJECT FILES



    # logInfo "cd to updated local project files"
    cd ~/${GITHUB_REPO_NAME}



    ## REPLACE ENV FILES
    logInfo "Moving project secrets in to env file"
    replaceEnvVars



    ## PROPERGATE ENV FILE
    cp .env.$DEPLOYMENT_ENV .env
    cp .env laravel/.env



    ## Removed files files that stop composer and npm
    # logInfo "Removed files files that stop composer and npm"
    # docker-compose -f docker-compose.yml run --user root --rm laravel rm -rf /var/www/package-lock.json || true
    # docker-compose -f docker-compose.yml run --user root --rm laravel rm -rf /var/www/public/mix-manifest.json || true



    ## Change file perms
    # logInfo "Change file perms laravel/.npmrc"
    # chmod 777 laravel/.npmrc



    ## BUILD DOCKER IMAGES
    logInfo "============================"
    logInfo "Starting docker images build"
    logInfo "============================"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml build
    else
        docker-compose build
    fi
    logInfo "============================"
    logInfo "Finished docker images build"
    logInfo "============================"



    ## LOGIN IN TO GITHUB GHCR
    # logInfo "Login to git ghcr"
    # echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin



    ## INSTALL AND RUN DOCKER IMAGES IN docker-composer FILE
    logInfo "Install and run the docker images in the docker-composer file"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml up -d
    else
        docker-compose up -d
    fi



    ## CHANGE FILES AROUND 2FOR INSTALLING
    logInfo "Change files around for installing"
    # docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R
    docker-compose -f docker-compose.yml run --user root --rm laravel chown $APP_USER /var/www/ -R



    if [[ $SCREEN_IS_PRESENT == true ]]; then
       while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_vendor"; do
           sleep 3
       done
    fi



    ## INSTALL PHP DEPS
    logInfo "Installing php deps"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml run --rm laravel composer install --no-dev
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml run --rm laravel composer update
    else
        docker-compose run --rm laravel composer install --no-dev
        docker-compose run --rm laravel composer update
    fi



    ## CHANGE FILE PERMS
    # logInfo "Change file perms"
    # docker-compose -f docker-compose.yml run --rm laravel php artisan queue:flush
    # docker-compose -f docker-compose.yml run --rm laravel php artisan queue:clear
    # docker-compose -f docker-compose.yml run --rm laravel php artisan cache:clear
    # docker-compose -f docker-compose.yml run --user root --rm laravel chmod 777 /var/www/ -R
    # docker-compose -f docker-compose.yml run --user root --rm laravel rm /var/www/package-lock.json
    # docker-compose -f docker-compose.yml run --user root --rm laravel rm /laravel/public/mix-manifest.json



    ## INSTALL NPM PACKAGES
    # logInfo "Install nom"
    # docker-compose -f docker-compose.yml run --rm laravel npm install



    ## BUILD JS TO BUNDLE
    # logInfo "Building javascript bundles"
    # docker-compose -f docker-compose.yml run --rm laravel npm run testing



    ## REMOVE OUR GITHUB TOKEN FROM DOCKER IMAGE
    # docker-compose -f docker-compose.yml run --user root --rm laravel rm /var/www/.npmrc



    ## RESTART THE CONTAINER
    logInfo "Restart the containers"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml down
    else
        docker-compose down
    fi



    ## LAST FILE PERMS FIX
    logInfo "Last file perms fix"
    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml run --user root --rm laravel chown $APP_USER /var/www/ -R
    else
        docker-compose run --user root --rm laravel chown $APP_USER /var/www/ -R
    fi



    ## RESET APP LOG FILES
    logInfo "Added deployment date to laravel logs"
    # touch ~/${GITHUB_REPO_NAME}/laravel/storage/logs/laravel.log
    # touch ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/laravel.log
    # touch ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue.log
    # touch ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue_high.log
    echo "" > ~/${GITHUB_REPO_NAME}/laravel/storage/logs/laravel.log
    echo "" > ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/laravel.log
    echo "" > ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue.log
    echo "" > ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue_high.log
    echo "DEPLOYMENT INFO: ${NOWDATESTAMP}" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/laravel.log
    echo "DEPLOYMENT INFO: ${NOWDATESTAMP}" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/laravel.log
    echo "DEPLOYMENT INFO: ${NOWDATESTAMP}" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue.log
    echo "DEPLOYMENT INFO: ${NOWDATESTAMP}" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue_high.log
    echo "" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/laravel.log
    echo "" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/laravel.log
    echo "" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue.log
    echo "" >> ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue_high.log
    chmod 777 ~/${GITHUB_REPO_NAME}/laravel/storage/logs/laravel.log
    chmod 777 ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/laravel.log
    chmod 777 ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue.log
    chmod 777 ~/${GITHUB_REPO_NAME}/laravel/storage/logs/supervisord/queue_high.log



    if [[ $SCREEN_IS_PRESENT == true ]]; then
       while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_node_modules"; do
           sleep 3
       done
       while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_vendor"; do
           sleep 3
       done
       while screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_public_scenes"; do
           sleep 3
       done
    fi



    if [[ -f ~/${GITHUB_REPO_NAME}/docker-compose.${DEPLOYMENT_ENV}.yml ]]; then
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml build
        docker-compose -f docker-compose.${DEPLOYMENT_ENV}.yml up -d
    else
        docker-compose build
        docker-compose up -d
    fi
}



## AFTER RUN CLEANUP
function deleteOldProjectFiles() {

    OLD_PROJECT_BYTE_SIZE=$(du ~/${GITHUB_REPO_NAME}_${NOWDATESTAMP} -sc | grep total)

    SPACESTR=" "
    EMPTYSTR=""
    TOTALSTR="total"

    SIZE=${SIZE/$SPACESTR/$EMPTYSTR}

    SIZE=${SIZE/$TOTALSTR/$EMPTYSTR}

    if [[ $SIZE -le 1175400 ]]; then
        echo "Not yet"
        # rm -R
    fi
}



## DELETE RUNNING FILE
function deleteRunningFile() {

    ## DELETE THE RUNNING FILE
    if [[ -f ~/deployment_running.txt ]]; then
        rm ~/deployment_running.txt
    fi
}

#
#
#
#
## END - SCRIPT FUNCTIONS









## START - SCRIPT PRE-CONFIGURE
#
#
#
#

## SET LOGGING TO TTY OR TO deployment.log
if [[ isCron == true ]]; then
    SCRIPT_DEBUG=false
else
    SCRIPT_DEBUG=true
fi


if [[ $CURL_IS_PRESENT == false ]]; then
    logError "Please install curl."
    exit
fi
if [[ $WHOIS_IS_PRESENT == false ]]; then
    logError "Please install whois."
    exit
fi

## CHECK IF SCRIPT IS ALREADY RUNNING
if [[ -f ~/deployment_running.txt ]]; then
     logInfo "Script already running."
     exit
fi


## CHECK IF BACKGROUND TASKS ARE STILL RUNNING
if [[ $SCREEN_IS_PRESENT == true ]]; then

    if screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_scenes"; then
        logError "${GITHUB_REPO_NAME}_deployment_move_scenes screen still running."
        exit;
    fi

    if screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_node_modules"; then
        logError "${GITHUB_REPO_NAME}_deployment_move_node_modules screen still running."
        exit;
    fi

    if screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_vendor"; then
        logError "${GITHUB_REPO_NAME}_deployment_move_vendor screen still running."
        exit;
    fi

    if screen -list | grep -q "${GITHUB_REPO_NAME}_deployment_move_public_scenes"; then
        logError "${GITHUB_REPO_NAME}_deployment_move_public_scenes screen still running."
        exit;
    fi
fi


## SAYING SOMETHING
logInfo ""
logInfo "Starting deployment update check."


## ECHO STARTTIME TO DEPLOYMENT LOG FILE
echo ${NOWDATESTAMP} > ~/deployment_running.txt


## ENTER PROJECT DIRECTORY
cd ~/$GITHUB_REPO_NAME/


## CHECK FOR GITHUB TOKEN
if [[ ! -f ~/.github_token ]]; then

    logError ""
    logError "Failed deployment ${NOWDATESTAMP}"
    logError ""
    logError "Missing github token file .github_token"
    logError "GITHUB_TOKEN=ghp_####################################"
    logError "public_repo, read:packages, repo:status, repo_deployment"
    exit 1;
fi


## CHECK FOR PROJECT VAR FILE
if [[ ! -f ~/.${GITHUB_REPO_NAME} ]]; then

    logError ""
    logError "Failed deployment ${NOWDATESTAMP}"
    logError ""
    logError "Missing twisted var file ~/.${GITHUB_REPO_NAME}"

    exit 1;
fi


## SET DEPLOY ENV VAR TO LOCATION
if [[ $DEPLOYMENT_ENV_LOCATION == true ]]; then
    set_location_var
    DEPLOYMENT_ENV=$ISOLOCATION
fi

## CHECK .env FILE
if [[ ! -f ~/${GITHUB_REPO_NAME}/.env ]]; then

    cp ~/${GITHUB_REPO_NAME}/.env.${DEPLOYMENT_ENV} ~/${GITHUB_REPO_NAME}/.env
fi

## LOAD .env VARS and GITHUB TOKEN AND SECRETS
logInfo "Loading .env & github var"
source ~/$GITHUB_REPO_NAME/.env
source ~/.github_token
## SECRETS
source ~/.${GITHUB_REPO_NAME}

#
#
#
#
### END - SCRIPT PRE-CONFIGURE










### START - SCRIPT RUNTIME
#
#
#
#

if [[ $# -eq 1 ]]; then
    logInfo ""
    logInfo "================================="
    logInfo "\/ Manually re-install started \/"
    logInfo "================================="
    doUpdate
    deleteRunningFile
    exit
fi

getProjectRemoteVersion

## CHECK FOR DEFAULT VARS
if [[ $APP_VERSION == '"<APP_VERSION>"' ]]; then

  ## replace with requested data version
  logError "Current version <APP_VERSION> AKA deployment failure somewhere"
  sed -i 's|"<APP_VERSION>"|'$NEW_VERSION'|' ~/$GITHUB_REPO_NAME/.env
else

  ## IF LOCAL VERSION AND REMOTE VERSION ARE THE SAME
  if [[ $APP_VERSION == $NEW_VERSION ]]; then

       logInfo "VERSION MATCH"

       deleteRunningFile

       logInfo "Finished deployment update check."
       exit;
  fi
 doUpdate
fi


logInfo "Delete the running file"


deleteRunningFile


## TELL USER
logInfo "Finished deployment update check."

exit 0;

#
#
#
#
# END - SCRIPT RUNTIME
