#!/bin/bash

mkdir -p /tmp/certs
cd /tmp/certs
wget --no-check-certificate https://10.3.1.10/webdav/home/Downloads/certs.tgz
tar xzf certs.tgz

keytool -importcert -noprompt -trustcacerts -alias k8s-ca_root -cacerts  -file root.crt  -storepass changeit
keytool -importcert -noprompt -trustcacerts -alias k8s-ca_server -cacerts  -file server.crt  -storepass changeit

cp *.crt /usr/local/share/ca-certificates/
cd /usr/local/share/ca-certificates/
update-ca-certificates -f
