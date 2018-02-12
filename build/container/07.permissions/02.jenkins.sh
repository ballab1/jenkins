#!/bin/bash

source "${TOOLS}/04.downloads/01.JENKINS"

chown -R jenkins:jenkins "${JENKINS['home']}"
chown -R jenkins:jenkins /usr/share/jenkins/ref

groupmod -n docker $(  getent group 999 | awk -F ':' '{ printf $1 }' )
usermod -G docker -a jenkins

