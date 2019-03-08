#!/bin/bash

: ${JENKINS_UID:?"Environment variable 'JENKINS_UID' not defined in '${BASH_SOURCE[0]}'"}
[ ${JENKINS_GITHUB_CREDENTIALS:-} ] || lib.file_env 'JENKINS_GITHUB_CREDENTIALS'

usermod -G "$DOCKER_GROUP" -a "$JENKINS_USER"
# if Docker socket exists, make sure we can access it
[ ! -S /var/run/docker.sock ] || chmod a+rw /var/run/docker.sock

declare -r referenceFolder="/usr/share/jenkins/ref"
declare -r pluginsFolder="${JENKINS_HOME}/plugins"

[ -e "${JENKINS_HOME}/logging.properties" ] || cp "${referenceFolder}/logging.properties" "${JENKINS_HOME}/logging.properties"

# clean out old plugins to ensure we are always at specified versions
[ ! -d "$pluginsFolder" ] || rm -rf "$pluginsFolder"
mkdir -p "$pluginsFolder"
cp -r "$referenceFolder/plugins"/* "$pluginsFolder"

chown -R "${JENKINS_UID}:$JENKINS_GID" "$JENKINS_HOME"
chown -R "${JENKINS_UID}:$JENKINS_GID" /usr/share/jenkins
[ -f "${JENKINS_HOME}.git" ] && rm ${JENKINS_HOME}/.git

if [ "${JENKINS_GITHUB_EMAIL}" ]; then
    git config --global user.email "${JENKINS_GITHUB_EMAIL}" || term.log "Failed to set global GIT 'user.email'\n" 'warn'
    unset JENKINS_GITHUB_EMAIL
fi
if [ "${JENKINS_GITHUB_NAME}" ]; then
    git config --system user.name "${JENKINS_GITHUB_NAME}" || term.log "Failed to set global GIT 'user.name'\n" 'warn'
    unset JENKINS_GITHUB_NAME
fi
if [ "${JENKINS_GITHUB_CREDENTIALS}" ]; then
    git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}" || term.log "Failed to set global GIT 'credential.user'\n" 'warn'
    unset JENKINS_GITHUB_CREDENTIALS
fi

# remove the GIT lock file (if it exists) before starting
declare idx_file=/var/jenkins_home/scm-sync-configuration/checkoutConfiguration/.git/index.lock
[ ! -e "$idx_file" ] || rm "$idx_file"

[ -d "${JENKINS_HOME}/scm-sync-configuration/checkoutConfiguration" ] && rm -rf "${JENKINS_HOME}/scm-sync-configuration/checkoutConfiguration"

if [ -d /var/ssh ] && [ $(ls -A /var/ssh/* | wc -l) -gt 0 ]; then
    mkdir -p "${JENKINS_HOME}/.ssh"
    cp /var/ssh/* "${JENKINS_HOME}/.ssh"/

    cd /root
    [ ! -e /root/.ssh ] || rm -rf /root/.ssh
    ln -s "${JENKINS_HOME}/.ssh" .
fi

[ ! -f "$(crf.STARTUP)/99.workdir.sh" ] || sed -i -e 's|crf.fixupDirectory|#crf.fixupDirectory|g' "$(crf.STARTUP)/99.workdir.sh"

find "$JENKINS_HOME" ! -user "$JENKINS_UID" -name '.*' -exec chown "$JENKINS_UID" '{}' \; || :
crf.fixupDirectory "$JENKINS_HOME" "$JENKINS_UID"

# fix up ssh access (do not touch original files)
if [ -d "${JENKINS_HOME}/.ssh" ]; then
    chmod 700 "${JENKINS_HOME}/.ssh"
    chmod 600 "${JENKINS_HOME}/.ssh"/*
    [ -f "${JENKINS_HOME}/.ssh/id_rsa.pub" ] && chmod 644 "${JENKINS_HOME}/.ssh/id_rsa.pub"
fi