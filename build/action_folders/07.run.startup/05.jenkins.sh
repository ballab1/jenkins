#!/bin/bash

: ${JENKINS_UID:?"Environment variable 'JENKINS_UID' not defined in '${BASH_SOURCE[0]}'"}

usermod -G "$DOCKER_GROUP" -a "$JENKINS_USER"
# if Docker socket exists, make sure we can access it
[ ! -S /var/run/docker.sock ] || chmod 666 /var/run/docker.sock

declare -r referenceFolder="/usr/share/jenkins/ref"
declare -r pluginsFolder="${JENKINS_HOME}/plugins"

[ -e "${JENKINS_HOME}/logging.properties" ] || cp "${referenceFolder}/logging.properties" "${JENKINS_HOME}/logging.properties"

# clean out old plugins to ensure we are always at specified versions
[ ! -d "$pluginsFolder" ] || rm -rf "$pluginsFolder"
mkdir -p "$pluginsFolder"
cp -r "$referenceFolder/plugins"/* "$pluginsFolder"

chown -R "${JENKINS_UID}:$JENKINS_GID" "$JENKINS_HOME"
chown -R "${JENKINS_UID}:$JENKINS_GID" /usr/share/jenkins
if [ "${JENKINS_GITHUB_EMAIL}" ]; then
    git config --global user.email "${JENKINS_GITHUB_EMAIL}"
    unset JENKINS_GITHUB_EMAIL
fi
if [ "${JENKINS_GITHUB_NAME}" ]; then
    git config --system user.name "${JENKINS_GITHUB_NAME}"
    unset JENKINS_GITHUB_NAME
fi
if [ "${JENKINS_GITHUB_CREDENTIALS}" ]; then
    git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}"
    unset JENKINS_GITHUB_CREDENTIALS
fi

# remove the GIT lock file (if it exists) before starting
declare idx_file=/var/jenkins_home/scm-sync-configuration/checkoutConfiguration/.git/index.lock
[ ! -e "$idx_file" ] || rm "$idx_file"

crf.fixupDirectory "$JENKINS_HOME" "$JENKINS_UID"

[ ! -e "${JENKINS_HOME}/scm-sync-configuration/checkoutConfiguration" ] || rm -rf "${JENKINS_HOME}/scm-sync-configuration/checkoutConfiguration"


cd /root
[ ! -e /root/.ssh ] || rm -rf /root/.ssh
ln -s "${JENKINS_HOME}/.ssh" .
chmod 700 "${JENKINS_HOME}/.ssh" 
chmod 600 "${JENKINS_HOME}/.ssh"/*
