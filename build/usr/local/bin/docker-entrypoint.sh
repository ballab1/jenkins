#!/bin/sh

set -o errexit
if [ "$1" = 'jenkins' ]; then
    /bin/tini -- "/usr/local/bin/jenkins.sh"
else
    exec $@
fi
