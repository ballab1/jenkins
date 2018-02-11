#!/bin/sh

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r config_entry=jenkins-setup
declare -r pluginsFile="/usr/share/jenkins/ref/plugins.txt"


#------------------------------------------------------------------
function getPlugins()
{
    local -r file=${1:?'Input parameter "file" must be defined'}

    local -a plugins
    readarray -t plugins < "$file"
    echo "${plugins[@]}"
}

#------------------------------------------------------------------
function prepare_environment()
{
    # clean out old plugins to ensure we are always at specified versions
    [[ -d "${JENKINS_HOME}/plugins" ]] && rm -rf "${JENKINS_HOME}/plugins" 
    mkdir  -p "${JENKINS_HOME}/plugins"

    chown -R jenkins:jenkins "$JENKINS_HOME"
    chown -R jenkins:jenkins /usr/share/jenkins/ref
    [[ "${JENKINS_GITHUB_EMAIL}" ]] && git config --system user.email "${JENKINS_GITHUB_EMAIL}"
    [[ "${JENKINS_GITHUB_NAME}" ]] && git config --system user.name "${JENKINS_GITHUB_NAME}"
    [[ "${JENKINS_GITHUB_CREDENTIALS}" ]] && git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}"
} 

#------------------------------------------------------------------
function set_exports()
{
    local -r tool_dir=${1:?'Input parameter "tool_dir" must be defined'}
    local envFile="$tool_dir/docker-environment.sh"
    local currentEnv=/tmp/env.sh
    
    if [ -e "$envFile" ]; then
        env > "$currentEnv"
        source "$envFile"
        source "$currentEnv"
        rm "$currentEnv"
    fi
}

#------------------------------------------------------------------


declare -r tools="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

set_exports  "$tools"

if [[ "$1" = 'jenkins' ]]; then
    # this is the primary (default) codepath invoked by the Dockerfile
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$1"
    sudo --preserve-env "$0" "$config_entry"
    "${tools}/install-plugins.sh" $( getPlugins "$pluginsFile" )
    /sbin/tini -- "${tools}/jenkins.sh"

elif [[ "$1" = "$config_entry" && "$(id -u)" -eq 0 ]]; then
    # this codepath is invoked (from above) to perpare the runtime environment. User is 'root' so chmod & chown succeed
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$@"
    prepare_environment

#elif [[ ${#@[*]} -gt 0 ]]; then
else
    # this codepath is invoked when a user invokes the container using 'docker run'
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" 'custom'
    shift
    exec $@
fi 
printf "\e[32m<<<<<<<< returning from \e[33m'%s'\e[0m\n" "$@" 