#!/bin/bash

_MYDIR=$( dirname "$0" )

rpm -ih https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum -y install puppet-agent augeas git

systemctl stop puppet
systemctl disable puppet

echo 'export PATH=${PATH}:/opt/puppetlabs/puppet/bin' >> /root/.bashrc
export PATH=${PATH}:/opt/puppetlabs/puppet/bin

cd ${_MYDIR}/../puppet

# this speeds up the puppet run because all/most packages are already installed
# Puppet is not really efficient with installing many packages
PREINSTALL=1
if [[ ${PREINSTALL} -eq 1 ]]; then
    cp ../yumrepos/*.repo /etc/yum.repos.d/ -Rvf
    yum install -y epel-release
    yum install -y ncdu telnet unzip sysstat htop lsof vim policycoreutils-devel httpd mod_ssl yum-plugin-priorities

    PHP_VERSION='php72'
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
    /opt/puppetlabs/puppet/bin/gem install r10k librarian-puppet
    librarian-puppet clean
    librarian-puppet install --verbose
    rm -Rf .librarian .tmp
    rm -Rf modules.tgz
    tar zfc modules.tgz modules

fi

time puppet apply --modulepath=$PWD/modules/:$PWD/extramodules/ setup.pp