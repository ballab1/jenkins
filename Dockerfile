FROM jenkins/jenkins:2.89.3-alpine

USER root

ARG TZ='America/New_York'
ARG JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL}
ARG JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME}
ARG JENKINS_GITHUB_TOKEN=${CFG_GITHUB_JENKINS_TOKEN}
ARG JENKINS_GITHUB_USER=${CFG_GITHUB_JENKINS_USER}

ENV VERSION=1.0.0 \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

 
LABEL version=$VERSION 

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/* 

USER jenkins
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["jenkins"] 
