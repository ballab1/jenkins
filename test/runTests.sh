#!/bin/bash

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
    sudo -E $0
    exit
fi
      
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"  

cd "$TOOLS"
chown -R jenkins:jenkins build PluginUpdator test
set -o verbose

docker run --rm \
           --volume "$TOOLS":/home/groovy/scripts \
           --workdir /home/groovy/scripts \
           groovy:2.6-jre-alpine \
           groovy test/test-dockerfile.groovy

chown -R bobb:bobb build PluginUpdator test
