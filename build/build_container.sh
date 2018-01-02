#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='JENKINS'

declare -r TZ=${TZ:-'America/New_York'}
declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 


declare -r JENKINS_PKGS="shadow sudo tzdata"

# global exceptions
declare -i dying=0
declare -i pipe_error=0


#----------------------------------------------------------------------------
# Exit on any error
function catch_error() {
    echo "ERROR: an unknown error occurred at $BASH_SOURCE:$BASH_LINENO" >&2
}

#----------------------------------------------------------------------------
# Detect when build is aborted
function catch_int() {
    die "${BASH_SOURCE[0]} has been aborted with SIGINT (Ctrl-C)"
}

#----------------------------------------------------------------------------
function catch_pipe() {
    pipe_error+=1
    [[ $pipe_error -eq 1 ]] || return 0
    [[ $dying -eq 0 ]] || return 0
    die "${BASH_SOURCE[0]} has been aborted with SIGPIPE (broken pipe)"
}

#----------------------------------------------------------------------------
function die() {
    local status=$?
    [[ $status -ne 0 ]] || status=255
    dying+=1

    printf "%s\n" "FATAL ERROR" "$@" >&2
    exit $status
}  

#############################################################################
function cleanup()
{
    printf "\nclean up\n"
}

#############################################################################
function header()
{
    local -r bars='+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    printf "\n\n\e[1;34m%s\nBuilding container: \e[0m%s\e[1;34m\n%s\e[0m\n" $bars $CONTAINER $bars
}
   
#############################################################################
function install_CUSTOMIZATIONS()
{
    local -r user=$1
    
    printf "\nAdd configuration and customizations\n"

    declare -a DIRECTORYLIST="/etc /usr /opt /var"
    for dir in ${DIRECTORYLIST}; do
        [[ -d "${TOOLS}/${dir}" ]] && cp -r "${TOOLS}/${dir}/"* "${dir}/"
    done
  
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh 

    echo "${user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    git config --system user.email "${JENKINS_GITHUB_EMAIL}"
    git config --system user.name "${JENKINS_GITHUB_NAME}"
    git config --system credential.user "${JENKINS_GITHUB_USER}:${JENKINS_GITHUB_TOKEN}"

    chmod 775 /usr/local/bin/plugins.sh 
    /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
    
    groupmod -n docker $(  getent group 999 | awk -F ':' '{ printf $1 }' )
    usermod -G docker -a $user
}

#############################################################################
function installAlpinePackages()
{
    apk update
    apk add --no-cache $JENKINS_PKGS
}

#############################################################################
function installTimezone()
{
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function setGitConfig()
{
    local -r github_email=$1
    local -r github_name=$2
    local -r github_user=$3
    local -r github_token=$4
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chmod 775 /usr/local/bin/* 
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

header
setGitConfig  "${JENKINS_GITHUB_EMAIL:?'Environment variable JENKINS_GITHUB_EMAIL must be defined'}" \
              "${JENKINS_GITHUB_NAME?:'Environment variable JENKINS_GITHUB_NAME must be defined'}" \
              "${JENKINS_GITHUB_USER:?'Environment variable JENKINS_GITHUB_USER must be defined'}" \
              "${JENKINS_GITHUB_TOKEN:?'Environment variable JENKINS_GITHUB_TOKEN must be defined'}"
installAlpinePackages
installTimezone 
install_CUSTOMIZATIONS 'jenkins'
setPermissions
exit 0
