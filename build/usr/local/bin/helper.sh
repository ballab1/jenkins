#!/bin/sh

declare -r runningEnv="/usr/local/bin/docker-environment.sh"
declare -r pluginsFile="/usr/share/jenkins/ref/plugins.txt"
declare -r pluginsReferenceFolder="/usr/share/jenkins/ref/plugins"
declare -r pluginsFolder="${JENKINS_HOME}/plugins"

#------------------------------------------------------------------
function helper.getPlugins()
{
    local -a plugins
    readarray -t plugins < "$pluginsFile"
    echo "${plugins[@]}"
}

#------------------------------------------------------------------
function helper.prepareEnvironment()
{
    # clean out old plugins to ensure we are always at specified versions
    [[ -d "$pluginsFolder" ]] && rm -rf "$pluginsFolder"
    mkdir -p "$pluginsFolder"
    cp -r "$pluginsReferenceFolder"/* "$pluginsFolder"

    chown -R jenkins:jenkins "$JENKINS_HOME"
    chown -R jenkins:jenkins /usr/share/jenkins/ref
    [[ "${JENKINS_GITHUB_EMAIL}" ]] && git config --system user.email "${JENKINS_GITHUB_EMAIL}"
    [[ "${JENKINS_GITHUB_NAME}" ]] && git config --system user.name "${JENKINS_GITHUB_NAME}"
    [[ "${JENKINS_GITHUB_CREDENTIALS}" ]] && git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}"
} 

#------------------------------------------------------------------
function helper.setExports()
{
    local currentEnv=/tmp/env.sh
    
    if [ -e "$runningEnv" ]; then
#        env > "$currentEnv"
        source "$runningEnv"
#        source "$currentEnv"
#        rm "$currentEnv"
    fi
}