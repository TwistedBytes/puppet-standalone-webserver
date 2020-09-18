#!/bin/bash

_MYDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd ${_MYDIR}/../puppet

rsync -ar setup.yaml /etc/puppetlabs/code/hieradata/
rsync -ar hiera.yaml /etc/puppetlabs/puppet/

/opt/puppetlabs/bin/puppet apply --modulepath=$PWD/modules/:$PWD/extramodules/ setup.pp
