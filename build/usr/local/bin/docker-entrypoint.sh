#!/bin/sh

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

#------------------------------------------------------------------
function set_exports()
{
    local -r tool_dir=$1
    
    env > /tmp/env.sh
    source "$tool_dir/docker-environment.sh"
    source /tmp/env.sh
    rm /tmp/env.sh
}

#------------------------------------------------------------------
function prepare_environment()
{
    chown -R jenkins:jenkins "$JENKINS_HOME"
    [[ "$JENKINS_HOME" ]] && chown -R jenkins:jenkins /usr/share/jenkins/ref
    [[ "${JENKINS_GITHUB_EMAIL}" ]] && git config --system user.email "${JENKINS_GITHUB_EMAIL}"
    [[ "${JENKINS_GITHUB_NAME}" ]] && git config --system user.name "${JENKINS_GITHUB_NAME}"
    [[ "${JENKINS_GITHUB_CREDENTIALS}" ]] && git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}"
} 


set_exports  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare -r config_entry=jenkins-setup
    
if [[ "$1" = 'jenkins' ]]; then
    # this is the primary (default) codepath invoked by the Dockerfile
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$1"
    sudo --preserve-env "$0" "$config_entry"
    /sbin/tini -- "/usr/local/bin/jenkins.sh"

elif [[ "$1" = "$config_entry" && "$(id -u)" -eq 0 ]]; then
    # this codepath is invoked (from above) to perpare the runtime environment. User is 'root' so chmod & chown succeed
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$@"
    prepare_environment "$config_file"

#elif [[ ${#@[*]} -gt 0 ]]; then
else
    # this codepath is invoked when a user invokes the container using 'docker run'
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" 'custom'
    shift
    exec $@
fi 
printf "\e[32m<<<<<<<< returning from \e[33m'%s'\e[0m\n" "$@" 