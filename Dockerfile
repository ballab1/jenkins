ARG FROM_BASE=openjdk:20180210
FROM $FROM_BASE 

ARG JENKINS_VERSION=${JENKINS_VERSION:-2.89.3}
ARG CONTAINER_VERSION=1.0.0
ARG JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL}
ARG JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME}
ARG JENKINS_GITHUB_CREDENTIALS=${CFG_GITHUB_JENKINS_USER}:${CFG_GITHUB_JENKINS_TOKEN}
ARG JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}
ARG jenkins_uid=1000
ARG jenkins_gid=1000

# version of this docker image
LABEL version=$CONTAINER_VERSION 
# jenkins version being bundled in this docker image
LABEL jenkins_version=$JENKINS_VERSION 


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/container/build.sh \
    && /tmp/container/build.sh 'JENKINS'
#RUN rm -rf /tmp/* 



# for main web interface:
EXPOSE 8080
# will be used by attached slave agents:
EXPOSE 50000
# Jenkins home directory is a volume, so configuration and build history can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

#USER jenkins
WORKDIR $JENKINS_HOME
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["jenkins"] 
