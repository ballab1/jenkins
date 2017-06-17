FROM jenkins:2.46.3-alpine

USER root
RUN touch /etc/gitconfig && \
    chown jenkins /etc/gitconfig
USER jenkins

COPY container/bin/* /usr/local/bin/
COPY container/init.groovy.d/* /usr/share/jenkins/ref/init.groovy.d/
COPY container/plugins.txt /usr/share/jenkins/ref/
COPY container/gitconfig /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
