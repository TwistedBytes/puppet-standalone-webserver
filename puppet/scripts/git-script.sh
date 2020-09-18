#!/bin/bash

set -x

yum install -y git

# needed for some environments
export HOME="/root"

cd ~
git clone https://github.com/TwistedBytes/puppet-standalone-webserver.git puppet-install

bash $PWD/puppet-install/puppet/scripts/initial.sh | tee install.txt

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=http

firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=https

firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --zone=public --add-service=ssh
