#!/bin/bash

mkdir -p /tmp/certs
cd /tmp/certs
wget --no-check-certificate https://10.3.1.10/webdav/home/Downloads/certs.tgz
tar xzf certs.tgz

for file in SohoBall_CA.crt SohoBall-Server.crt; do
  keytool -importcert -noprompt -trustcacerts -alias k8s-ca_root -cacerts  -file "$file"  -storepass changeit
  cp "$file" /usr/local/share/ca-certificates/
done

cd /usr/local/share/ca-certificates/
update-ca-certificates -f
