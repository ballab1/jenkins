#!/bin/bash

declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"  

docker run --rm \
           --volume "$TOOLS":/home/groovy/scripts \
           --workdir /home/groovy/scripts \
           groovy:2.6-jre-alpine \
           groovy PluginUpdator/latestPlugins.groovy
