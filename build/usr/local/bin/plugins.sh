#! /bin/bash


function getPlugins() {
    local -r file=$1
    local -a plugins
    readarray -t plugins < "$file"
    echo "${plugins[@]}"
}

declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare -r pluginsFile="${1:-${TOOLS}/plugins.txt}"

"${TOOLS}/install-plugins.sh" $( getPlugins "$pluginsFile" )
#"${TOOLS}/plugins.org.sh" "$pluginsFile"
