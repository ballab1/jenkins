#!/bin/bash -x

function get_script_dir () {
     local SOURCE="${BASH_SOURCE[0]}"
#     # While $SOURCE is a symlink, resolve it
#     while [ -h "$SOURCE" ]; do
#          local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
#          SOURCE="$( readlink "$SOURCE" )"
#          # If $SOURCE was a relative symlink (so no "/" as prefix, need to resolve it relative to the symlink base directory
#          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
#     done
     echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}


declare -r config_entry='jenkins-setup' 
declare -r tools="$( get_script_dir )"  
source "${tools}/helper.sh"

export 'JAVA_OPTS=-Djava.util.logging.config.file=/var/jenkins_home/log.properties -Djenkins.install.runSetupWizard=false'
export JENKINS_HOME=/var/jenkins_home
export JENKINS_OPTS=--prefix=/jenkins
export JENKINS_UC=https://updates.jenkins.io
export JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
export COPY_REFERENCE_FILE_LOG=/var/jenkins_home/copy_reference_file.log
export JENKINS_SLAVE_AGENT_PORT=50000
echo "${#@[*]}"
#helper.setExports

if [[ "$1" = 'jenkins' ]]; then
    # this is the primary (default) codepath invoked by the Dockerfile
    printf "\e[32m>>>>>>>> entering \e[33m'%s'\e[0m\n" "$1"
#    sudo --preserve-env "$0" "$config_entry"
    /sbin/tini -s -- "${tools}/jenkins.sh"

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
