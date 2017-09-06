# Basic jenkins container populated with required plugins for home setup

 based on standard container:  Jenkins::2.60.3-alpine

to build & run
```bash
 docker build --tag jenkins --rm=true \
              --build-arg JENKINS_GITHUB_EMAIL=${CFG_GITHUB_JENKINS_EMAIL} \
              --build-arg JENKINS_GITHUB_NAME=${CFG_GITHUB_JENKINS_NAME} \
              --build-arg JENKINS_GITHUB_TOKEN=${CFG_GITHUB_JENKINS_TOKEN} \
              --build-arg JENKINS_GITHUB_USER=${CFG_GITHUB_JENKINS_USER} \
        https://github.com/ballab1/jenkins.git
 docker run --name jenkins -p 8080:8080 -v $PWD/jenkins_home:/var/jenkins_home -d jenkins:latest
```

gotchas:
  if the local '$PWD/jenkins_home' folder does not exist, or does not have write permissions, the container may not run
