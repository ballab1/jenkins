ARG FROM_BASE=${DOCKER_REGISTRY:-ubuntu-s2.home:5000/}${CONTAINER_OS:-alpine}/openjdk/${JAVA_VERSION:-8.171.11-r0}:${BASE_TAG:-latest}
FROM $FROM_BASE 

# name and version of this docker image
ARG CONTAINER_NAME=jenkins
# Specify CBF version to use with our configuration and customizations
ARG CBF_VERSION

# include our project files
COPY build Dockerfile /tmp/

# set to non zero for the framework to show verbose action scripts
#    (0:default, 1:trace & do not cleanup; 2:continue after errors)
ENV DEBUG_TRACE=0


ARG JENKINS_GITHUB_EMAIL=${CFG_GITHUB_EMAIL}
ARG JENKINS_GITHUB_NAME=${CFG_GITHUB_NAME}
ARG JENKINS_GITHUB_CREDENTIALS=${CFG_GITHUB_USER}:${CFG_GITHUB_TOKEN}
ARG JENKINS_HOME=/var/jenkins_home
ARG jenkins_uid=100
ARG jenkins_gid=1004
ARG docker_uid=999
ARG docker_gid=999

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION=2.235.1
LABEL version.jenkins=$JENKINS_VERSION 


# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME" "$DEBUG_TRACE" \
    && ([ "$DEBUG_TRACE" != 0 ] || rm -rf /tmp/*) 


# execute this container as jenkins
USER jenkins
# expose main web interface:
EXPOSE 8080
# expose port used by attached slave agents:
EXPOSE 50000
# Jenkins home directory is a volume, so configuration and build history can be persisted and survive image upgrades
VOLUME $JENKINS_HOME
WORKDIR $JENKINS_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"] 
CMD ["jenkins"] 
