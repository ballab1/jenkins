# Basic jenkins container populated with required plugins for home setup

 based on standard container:  Jenkins:1.651.2-alpine

to build & run

 docker build --tag jenkins --rm=true https://github.com/ballab1/jenkins.git
 docker run --name jenkins -p 8080:8080 -v $PWD/jenkins_home:/var/jenkins_home -d jenkins:latest

gotchas:
  if the local 'jenkins_home' folder does not exist, or does not have write permissions, the container may not run
