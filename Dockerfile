FROM jenkins/jenkins:2.89.2-alpine

USER root

ARG JENKINS_GITHUB_EMAIL=''
ARG JENKINS_GITHUB_NAME=''
ARG JENKINS_GITHUB_USER=''
ARG JENKINS_GITHUB_TOKEN=''

ENV VERSION=1.0.0 \
    TZ='America/New_York' \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

LABEL version=$VERSION 

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \     && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/* 

USER jenkins
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["jenkins"] 
