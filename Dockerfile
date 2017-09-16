FROM jenkins/jenkins:2.73.1-alpine

ENV JENKINS_PKGS="tzdata sudo" \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER root

ARG TZ=UTC
RUN apk update \
    && apk add --no-cache $JENKINS_PKGS \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

ARG JENKINS_GITHUB_EMAIL
ARG JENKINS_GITHUB_NAME
ARG JENKINS_GITHUB_USER
ARG JENKINS_GITHUB_TOKEN
RUN git config --system user.email "${JENKINS_GITHUB_EMAIL}" \
    && git config --system user.name "${JENKINS_GITHUB_NAME}" \
    && git config --system credential.user "${JENKINS_GITHUB_USER}:${JENKINS_GITHUB_TOKEN}"


USER jenkins
COPY container/bin/* /usr/local/bin/
COPY container/init.groovy.d/* /usr/share/jenkins/ref/init.groovy.d/
COPY container/plugins.txt /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
