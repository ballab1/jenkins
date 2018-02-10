ARG CODE_VERSION=openjdk:20180207
FROM $CODE_VERSION 

ARG JENKINS_VERSION
ARG jenkins_uid=1000
ARG jenkins_gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL}
ARG JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME}
ARG JENKINS_GITHUB_TOKEN=${CFG_GITHUB_JENKINS_TOKEN}
ARG JENKINS_GITHUB_USER=${CFG_GITHUB_JENKINS_USER}
ARG JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}

# jenkins version being bundled in this docker image
ENV JENKINS_VERSION=${JENKINS_VERSION:-2.60.3} \
    COPY_REFERENCE_FILE_LOG=$JENKINS_HOME/copy_reference_file.log \
    JENKINS_SLAVE_AGENT_PORT=${agent_port} \
    VERSION=1.0.0

LABEL version=$VERSION 
LABEL jenkins_version=$JENKINS_VERSION 


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/container/build.sh \
    && /tmp/container/build.sh 'JENKINS'
RUN rm -rf /tmp/* 

EXPOSE ${http_port}          # for main web interface:
EXPOSE ${agent_port}         # will be used by attached slave agents:
VOLUME ${JENKINS_HOME}       # Jenkins home directory is a volume, so configuration and build history can be persisted and survive image upgrades

USER jenkins
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["jenkins"] 
