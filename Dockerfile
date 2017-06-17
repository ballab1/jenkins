FROM jenkins:2.46.3-alpine

USER jenkins

COPY container/bin/* /usr/local/bin/
COPY container/init.groovy.d/* /usr/share/jenkins/ref/init.groovy.d/
COPY container/plugins.txt /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

USER root
RUN git config --system user.email "${CFG_GITHUB_JENKINS_EMAIL}" && \
    git config --system user.name "${CFG_GITHUB_JENKINS_NAME}" && \
    git config --system credential.user "${CFG_GITHUB_JENKINS_USER}:${CFG_GITHUB_JENKINS_TOKEN}"

USER jenkins
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
