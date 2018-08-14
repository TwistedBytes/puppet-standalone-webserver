require ::tbsite::packages
require ::apache_php::apache
require ::apache_php::customers
require ::apache_php::sites


#
# class { 'tbuser':
#   users => { site =>
#   {
#     gid       => 'site',
#     shell     => '/bin/bash',
#     user_hash => 'keep',
#   }
#
#   }
# }

# apache_php::allinone { 'site':
#   vhostname => 'site',
#   vhostbase => '/var/www/vhosts',
#   username  => 'site',
#
# }
