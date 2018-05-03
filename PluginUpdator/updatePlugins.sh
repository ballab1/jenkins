#!/bin/bash

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
    sudo -E $0 "$(id -nu):$(id -ng)"
    exit
fi
      
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" 


function setPermissions()
{
    local -r mode=${1-'o-w'}
    local -r owner=$2

    chmod "$mode" "${TOOLS}/Dockerfile"
    chmod "$mode" "${TOOLS}/build/usr/share/jenkins/ref/plugins.txt"

    local -ra dirs=( build/usr/share/jenkins PluginUpdator test )
    for dir in "${dirs[@]}" ; do
        chmod "$mode" "${TOOLS}/$dir"
    done
    [ $mode = 'o-w' ] && chown "$owner" PluginUpdator/*
}

cd "$TOOLS"

setPermissions 'o+w'
set -o verbose

docker run --rm \
           --volume "$TOOLS":/home/groovy/scripts \
           --workdir /home/groovy/scripts \
           groovy:2.6-jre-alpine \
           groovy PluginUpdator/latestPlugins.groovy

set +o verbose
setPermissions 'o-w' "$@"
