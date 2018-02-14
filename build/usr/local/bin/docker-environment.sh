#!/bin/sh

#  do not modify this file. 
#
#  It gets generated when the container is built, and is used to setup the environment when the container runs
#

#                agent_port: 50000
#                http_port: 8080
#declare -x JENKINS_VERSION=$JENKINS_VERSION
declare -x JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}
declare -x COPY_REFERENCE_FILE_LOG="$JENKINS_HOME/copy_reference_file.log"
declare -x JENKINS_SLAVE_AGENT_PORT=${agent_port:-50000}
declare -x JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties -Djenkins.install.runSetupWizard=false"
declare -x JENKINS_OPTS="--prefix=/jenkins"
