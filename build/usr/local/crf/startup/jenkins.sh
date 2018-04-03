#!/bin/sh

declare -r pluginsReferenceFolder="/usr/share/jenkins/ref/plugins"
declare -r pluginsFolder="${JENKINS_HOME}/plugins"


# clean out old plugins to ensure we are always at specified versions
[[ ! -d "$pluginsFolder" ]] || rm -rf "$pluginsFolder"
mkdir -p "$pluginsFolder"
cp -r "$pluginsReferenceFolder"/* "$pluginsFolder"

chown -R jenkins:jenkins "$JENKINS_HOME"
chown -R jenkins:jenkins /usr/share/jenkins/ref
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