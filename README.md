# Jenkins_container
## Basic jenkins container populated with required plugins for home setup

based on standard container:  Jenkins:2.121.1 and aline:3.7

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

###gotchas:
  if the local 'jenkins_home' folder does not exist, or does not have write permissions, the container may not run
  to ensure that 'jenkins_home' does have the correct permissions, you can run the command
```bash
      find jenkins_home -type d -exec chmod ugo+rwx '{}' \;
      find jenkins_home -type f -exec chmod ugo+rw '{}' \;  
```

###Updating to latest plugins
For details about updating the 'plugins.txt' file refer to [README](PluginUpdator/README.md) in the PluginUpdator folder

## setting up the SCM-Configuration Plugin
this uses SSH, so an ssh key (~/.ssh/id_rsa.pub) has to be present. This has to be uploaded to GITHub for the account used to save the configuration