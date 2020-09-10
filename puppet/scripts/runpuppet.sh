#!/bin/bash

_MYDIR=$( dirname "$0" )

cd ${_MYDIR}/../puppet

rsync -ar setup.yaml /etc/puppetlabs/code/hieradata/
rsync -ar hiera.yaml /etc/puppetlabs/puppet/

/opt/puppetlabs/bin/puppet apply --modulepath=$PWD/modules/:$PWD/extramodules/ setup.pp
/opt/puppetlabs/bin/puppet apply --modulepath=$PWD/modules/:$PWD/extramodules/ setup.pp

if [[ -f ~root/.ssh/authorized_keys ]]; then
  [[ ! -d ~default/.ssh ]] && mkdir ~default/.ssh
  rsync ~root/.ssh/authorized_keys ~default/.ssh
  chown -Rf default:default ~default/.ssh
fi



