#!/bin/bash

declare github_email="${JENKINS_GITHUB_EMAIL:?'Environment variable JENKINS_GITHUB_EMAIL must be defined'}"
declare github_name="${JENKINS_GITHUB_NAME?:'Environment variable JENKINS_GITHUB_NAME must be defined'}"
declare github_credentials="${JENKINS_GITHUB_CREDENTIALS:?'Environment variable JENKINS_GITHUB_CREDENTIALS must be defined'}"

echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

git config --system user.email "${github_email}"
git config --system user.name "${github_name}"
git config --system credential.user "${github_credentials}"

chmod 775 /usr/local/bin/plugins.sh 
/usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

groupmod -n docker $(  getent group 999 | awk -F ':' '{ printf $1 }' )
usermod -G docker -a $user
