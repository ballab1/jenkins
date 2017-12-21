#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
declare -r JENKINS_PKGS="tzdata sudo" \
declare -x TZ=${TZ:-'America/New_York'}
declare -x JENKINS_GITHUB_EMAIL=${JENKINS_GITHUB_EMAIL:-''}
declare -x JENKINS_GITHUB_NAME=${JENKINS_GITHUB_NAME:-''}
declare -x JENKINS_GITHUB_USER=${JENKINS_GITHUB_USER:-''}
declare -x JENKINS_GITHUB_TOKEN=${JENKINS_GITHUB_TOKEN:-''}


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
function installPackages() {
    apk update
    apk add --no-cache $JENKINS_PKGS
}

#############################################################################
function installTimezone() {
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function cleanup()
{
    printf "\nclean up\n"
}

#############################################################################
function installCUSTOMIZATIONS()
{
    printf "\nAdd configuration and customizations\n"
    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh 

    git config --system user.email "${JENKINS_GITHUB_EMAIL}"
    git config --system user.name "${JENKINS_GITHUB_NAME}"
    git config --system credential.user "${JENKINS_GITHUB_USER}:${JENKINS_GITHUB_TOKEN}"

    chmod 775 /usr/local/bin/plugins.sh 
    /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chown root:root /etc/sudoers.d/*
    chmod 600 /etc/sudoers.d/*
    
    chmod 775 /usr/local/bin/* 
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

installPackages
installTimezone 
installCUSTOMIZATIONS
setPermissions
cleanup
exit 0
