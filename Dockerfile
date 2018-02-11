ARG CODE_VERSION=openjdk:20180207
FROM $CODE_VERSION 

ARG JENKINS_VERSION
ARG jenkins_uid=1000
ARG jenkins_gid=1000
ARG JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL}
ARG JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME}
ARG JENKINS_GITHUB_CREDENTIALS=${CFG_GITHUB_JENKINS_USER}:${CFG_GITHUB_JENKINS_TOKEN}
ARG JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}

# jenkins version being bundled in this docker image
ENV JENKINS_VERSION=${JENKINS_VERSION:-2.89.3} \
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



# for main web interface:
EXPOSE 8080
# will be used by attached slave agents:
EXPOSE 50000
# Jenkins home directory is a volume, so configuration and build history can be persisted and survive image upgrades
VOLUME ${JENKINS_HOME}

USER jenkins
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["jenkins"] 
