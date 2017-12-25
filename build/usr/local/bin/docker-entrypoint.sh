#!/bin/sh

[[ "${JENKINS_GITHUB_EMAIL}" ]] && sudo git config --system user.email "${JENKINS_GITHUB_EMAIL}"
[[ "${JENKINS_GITHUB_NAME}" ]] && sudo git config --system user.name "${JENKINS_GITHUB_NAME}"
[[ "${JENKINS_GITHUB_USER}" && "${JENKINS_GITHUB_TOKEN}" ]] && sudo git config --system credential.user "${JENKINS_GITHUB_USER}:${JENKINS_GITHUB_TOKEN}"

set -o errexit

if [ "$1" = 'jenkins' ]; then
        /bin/tini -- "/usr/local/bin/jenkins.sh"
    else
        exec $@
fi
