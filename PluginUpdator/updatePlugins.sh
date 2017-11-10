#!/bin/bash

declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"  

docker run --rm -v "$TOOLS":/home/groovy/scripts -w /home/groovy/scripts groovy:2.6-jre-alpine groovy PluginUpdator/latestPlugins.groovy
