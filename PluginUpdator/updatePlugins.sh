#!/bin/bash

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
    sudo -E $0 "$(id -nu):$(id -ng)" "$(id -u):$(id -g)"
    exit
fi

declare -r TOOLS="$( readlink -f "$( dirname "${BASH_SOURCE[0]}" )/.." )"


function setPermissions()
{
    local -r owner=${1:?}
    local -r mode=${2:-'o-w'}

    chmod "$mode" "${TOOLS}/Dockerfile"
    chmod "$mode" "${TOOLS}/build/usr/share/jenkins/ref/plugins.txt"

    local -ra dirs=( build/usr/share/jenkins PluginUpdator test )
    for dir in "${dirs[@]}" ; do
        chmod -R "$mode" "${TOOLS}/$dir"
        chown -R "$owner" "${TOOLS}/$dir"
    done
    [ "$mode" = 'o-w' ] && chown "$owner" PluginUpdator/*
}

cd "$TOOLS"

#setPermissions "$1" 'o+w'
set -o verbose

docker run --rm \
           --volume "$TOOLS/PluginUpdator":/home/groovy/scripts \
           --volume "$TOOLS":/home/groovy/data \
           --volume "${TOOLS}/../versions":/home/groovy/versions \
           --workdir /home/groovy \
           --user "$2" \
           ${DOCKER_REGISTRY:-}docker.io/groovy:2.6-jre-alpine \
           groovy scripts/latestPlugins.groovy

set +o verbose
#setPermissions "$1" 'o-w'
