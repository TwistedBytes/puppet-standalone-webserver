#!/bin/bash

_MYDIR=$( dirname "$0" )

rpm -ih https://yum.puppet.com/puppet6/puppet-release-el-7.noarch.rpm
yum -y install puppet-agent augeas git

systemctl stop puppet
systemctl disable puppet

augtool << EOT1
set /files/etc/puppetlabs/puppet/puppet.conf/main/disable_warnings deprecations
save
EOT1

echo 'export PATH=${PATH}:/opt/puppetlabs/puppet/bin' >> /root/.bashrc
export PATH=${PATH}:/opt/puppetlabs/puppet/bin

cd ${_MYDIR}/../puppet

mkdir -p /etc/puppetlabs/code/hieradata/

# this speeds up the puppet run because all/most packages are already installed
# Puppet is not really efficient with installing many packages
PREINSTALL=0
if [[ ${PREINSTALL} -eq 1 ]]; then
    cp ../yumrepos/*.repo /etc/yum.repos.d/ -Rvf
    yum install -y epel-release
    yum install -y ncdu telnet unzip sysstat htop lsof vim policycoreutils-devel httpd mod_ssl yum-plugin-priorities psmisc nano wget bzip2 mailx

    PHP_VERSION='php73'
    PHP7_PREFIX="${PHP_VERSION}-"

    for i in php-pear php-odbc php-soap php-common php-cli php-xmlrpc php-dba   \
        php-mbstring php-pgsql php-gd php-mysqlnd php-pdo php-imap php-bcmath php-xml php-mcrypt   \
        php-json php-pdo-dblib php-process php-intl php-pecl-imagick php-pecl-zip \
        php-opcache php-fpm php-pecl-xdebug php-tidy php-gmp php-ldap php-pspell \
        php-sodium; do

        echo ${PHP7_PREFIX}${i}
    done | xargs yum -y install

    rm -Rf modules .librarian .tmp
    tar xzf modules.tgz

else
    /opt/puppetlabs/puppet/bin/gem install -q --silent r10k librarian-puppet
    librarian-puppet clean
    librarian-puppet install
    rm -Rf .librarian .tmp
    rm -Rf modules.tgz
    tar zfc modules.tgz modules
fi

${_MYDIR}/runpuppet.sh

if [[ 0 -eq 1 ]]; then

cat << 'EOT' > /var/www/vhosts/default/site/docroot/index.php
<?php

phpinfo();
EOT

fi