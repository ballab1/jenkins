#!/bin/bash

declare -r config_entry='jenkins-setup' 
declare -r tools="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
source "${tools}/helper.sh"


helper.setExports

if [[ "$1" = 'jenkins' ]]; then
    # this is the primary (default) codepath invoked by the Dockerfile
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$1"
    sudo --preserve-env "$0" "$config_entry"
    /sbin/tini -- "${tools}/jenkins.sh"

elif [[ "$1" = "$config_entry" && "$(id -u)" -eq 0 ]]; then
    # this codepath is invoked (from above) to perpare the runtime environment. User is 'root' so chmod & chown succeed
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$*"
    helper.prepareEnvironment

#elif [[ ${#@[*]} -gt 0 ]]; then
else
    # this codepath is invoked when a user invokes the container using 'docker run'
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" 'custom'
    shift
    exec $@
fi 
printf "\e[32m<<<<<<<< returning from \e[33m'%s'\e[0m\n" "$*" 
