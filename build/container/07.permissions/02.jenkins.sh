#!/bin/bash

declare tools="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" 
source "${tools}/04.downloads/01.JENKINS"

chown -R jenkins:jenkins "${JENKINS['home']}"
chown -R jenkins:jenkins /usr/share/jenkins/ref