$!/bin/bash

yum install -y git

cd ~
git clone https://github.com/TwistedBytes/puppet-standalone-webserver.git puppet-install

bash $PWD/puppet-install/puppet/scripts/initial.sh | tee install.txt

