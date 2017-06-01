FROM jenkins:2.46.2

COPY container/bin/* /usr/local/bin/
COPY container/init.groovy.d/* /usr/share/jenkins/ref/init.groovy.d/
COPY container/plugins.txt /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
