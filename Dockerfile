FROM jenkins:2.46.3-alpine

USER root

ENV JENKINS_HOME="/var/jenkins_home"  \
    JENKINS_GITHUB_TOKEN="${CFG_GITHUB_JENKINS_TOKEN}"  \
    JENKINS_GITHUB_EMAIL="${CFG_GITHUB_JENKINS_EMAIL}"  \
    JENKINS_GITHUB_NAME="${CFG_GITHUB_JENKINS_NAME}"    \
    JENKINS_GITHUB_USER="${CFG_GITHUB_JENKINS_USER}"    \
    JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties"  \
    TZ="America/New_York"

# volumes which can/should be exported
#            - ./jenkins/home:/var/jenkins_home
#            - ./jenkins/container/.ssh:/var/jenkins_home/.ssh
#            - ./jenkins/container/.gitconfig:/var/jenkins_home/.gitconfig

RUN touch /etc/gitconfig && \
    chown jenkins /etc/gitconfig && \
    chown jenkins -R "$JENKINS_HOME"

COPY container/bin/* /usr/local/bin/
COPY container/init.groovy.d/* /usr/share/jenkins/ref/init.groovy.d/
COPY container/plugins.txt /usr/share/jenkins/ref/
COPY container/gitconfig /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt


VOLUME ["/var/jenkins_home"]
WORKDIR /var/jenkins_home/

EXPOSE 8080
USER jenkins

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
