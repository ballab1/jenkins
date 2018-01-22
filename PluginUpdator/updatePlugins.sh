#!/bin/bash

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
    sudo --preserve-env $0 "$@"
    exit
fi
      
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" 

function setPermissions()
{
    local -r mode=${1-'o-w'}

    chmod "$mode" "${TOOLS}/Dockerfile"
    chmod "$mode" "${TOOLS}/build/usr/share/jenkins/ref/plugins.txt"

    local -r dirs='build/usr/share/jenkins PluginUpdator test'
    for dir in $dirs ; do
        chmod "$mode" "${TOOLS}/$dir"
    done
    [ $mode = 'o-w' ] && chown bobb:bobb PluginUpdator/*
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
setPermissions 'o-w'
