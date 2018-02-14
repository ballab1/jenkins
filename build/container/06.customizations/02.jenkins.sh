#!/bin/bash

declare -r tools="/usr/local/bin"
source "${tools}/jenkins.helper"

cat > "$runningEnv" <<EOF
#!/bin/bash
# this is a generated file!!  DO NOT MODIFY

#                agent_port: 50000
#                http_port: 8080
#declare -x JENKINS_VERSION=$JENKINS_VERSION
export JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties -Djenkins.install.runSetupWizard=false"
export JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}
export JENKINS_OPTS="--prefix=/jenkins" 
export JENKINS_UC="https://updates.jenkins.io"
export JENKINS_UC_EXPERIMENTAL="https://updates.jenkins.io/experimental"
export COPY_REFERENCE_FILE_LOG="$JENKINS_HOME/copy_reference_file.log"
export JENKINS_SLAVE_AGENT_PORT=${agent_port:-50000}
EOF

echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

[ "$JENKINS_GITHUB_EMAIL" ] && git config --system user.email "${JENKINS_GITHUB_EMAIL}"
[ "$JENKINS_GITHUB_NAME" ] && git config --system user.name "${JENKINS_GITHUB_NAME}"
[ "$JENKINS_GITHUB_CREDENTIALS" ] && git config --system credential.user "${JENKINS_GITHUB_CREDENTIALS}"


# download plugins and save a copy to restore at each runtime
source "$runningEnv"
chmod 775 "${tools}/install-plugins.sh" 
"${tools}/install-plugins.sh" $( jenkins.getPlugins )
