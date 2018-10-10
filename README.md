# Jenkins_container
## Basic jenkins container populated with required plugins for home setup

based on standard container:  Jenkins:2.138.2 and aline:3.8

to build & run
```bash
 docker build --tag jenkins --rm=true \
              --build-arg JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL} \
              --build-arg JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME} \
              --build-arg JENKINS_GITHUB_TOKEN=${CFG_GITHUB_JENKINS_TOKEN} \
              --build-arg JENKINS_GITHUB_USER=${CFG_GITHUB_JENKINS_USER} \
        https://github.com/ballab1/jenkins.git
 mkdir jenkins_home
 docker run --name jenkins -p 8080:8080 -v $PWD/jenkins_home:/var/jenkins_home -d jenkins:latest
```

### gotchas:
  if the local 'jenkins_home' folder does not exist, or does not have write permissions, the container may not run
  to ensure that 'jenkins_home' does have the correct permissions, you can run the command
```bash
      find jenkins_home -type d -exec chmod ugo+rwx '{}' \;
      find jenkins_home -type f -exec chmod ugo+rw '{}' \;  
```

### Updating to latest plugins
For details about updating the 'plugins.txt' file refer to [README](PluginUpdator/README.md) in the PluginUpdator folder

## setting up the SCM-Configuration Plugin
this uses SSH, so an ssh key (~/.ssh/id_rsa.pub) has to be present. This has to be uploaded to GITHub for the account used to save the configuration

## Validation of Docker Image

### Prerequisite

The validation of docker image uses the framework from [bash unit](https://github.com/pgrange/bash_unit).  In order to run the test, please download this binary to run.

One way to get this installed is to do the following, but as always please refer to the official instructions as steps can change:

```bash
sudo wget https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit -O /usr/local/bin/bash_unit
sudo chmod +x /usr/local/bin/bash_unit
```

### Running the Validation

By using *bash_unit*, you can perform some validation to ensure this container does not hit regression

```bash
$ bash_unit -f tap test/test-docker-image.sh
# Running tests in test/test-docker-image.sh
ok ? test_jenkins_user_exists
ok ? test_jenkins_version
not ok ? test_plugin_list
#  expected [8833aa708b806d593602ad72ecefd1652120f4b70e5c5b5ef94ad905f247f57d  -] but was [b848a2337b24551b04bc783331bcebfaabcfaa48d4dc8aea9bdf0fde8681783c  -]
# test-docker-image.sh:117:test_plugin_list()
```

As you can see the above, the test to check the user and jenkins version passed but a recent update to the plugin failed. Until this report is added to test case, it can be debugged manually based on the test by creating two plugins list file. The construction of the manual steps are derived from the test script and likely a more advanced step worth covering here.  

The expected (git) and actual (installed into container) plugin list can be generated:

```bash
cat test/plugin-dependencies.txt build/usr/share/jenkins/ref/plugins.txt| sort -fu > plugins-expected.txt
docker-compose up -d
wget -nc http://localhost:8080/jnlpJars/jenkins-cli.jar 
java -jar ./jenkins-cli.jar -noKeyAuth -s http://localhost:8080/ list-plugins | \
    sed -e 's/([^()]*)//g' | \
    awk '{print $1":"$NF}' | \
    sort -fu > plugins-actual.txt
```

Once you have the two list a simple diff can show plugin dependencies introduced:
```diff
diff -u test-plugins-git.txt test-plugins-complete.txt
--- plugins-expected.txt        2018-10-03 17:32:20.741707309 -0400
+++ plugins-actual.txt   2018-10-03 17:31:38.655113120 -0400
@@ -82,6 +82,7 @@
 jquery:1.12.4-0
 jsch:0.1.54.2
 junit:1.26.1
+kubernetes-credentials:0.4.0
 kubernetes:1.12.6
 ldap:1.20
 leastload:2.0.1
```

As you can see above, the introduction of kubernets automatically installed `kubernetes-credentials` differing from the actual `plugins.txt` one `kubernetes` change.  Once this has been identified, the test can be updated to calculate the correct checksum:
```diff
diff --cc test/plugin-dependencies.txt
index 7060737,4e29251..0000000
--- a/test/plugin-dependencies.txt
+++ b/test/plugin-dependencies.txt
@@@ -11,6 -11,6 +11,7 @@@ jenkins-design-language:1.8.
  jira:3.0.2
  jquery:1.12.4-0
  jsch:0.1.54.2
++kubernetes-credentials:0.4.0
  mercurial:2.4
  publishtokafka:1.0
  pubsub-light:1.12
```
