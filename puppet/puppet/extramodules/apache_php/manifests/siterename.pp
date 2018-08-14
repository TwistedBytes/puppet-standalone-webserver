/*
add this to hiera

apache_php::siterename::sites:
  test.newlease6.nl:
    to: test.newlease7.nl
*/

class apache_php::siterename (
  $sites = undef,
){

  file { '/usr/local/sbin/renamesite.sh':
    mode   => '0700',
    source => "puppet:///modules/${module_name}/renamesite.sh",
  }

  if ($sites != undef) {
    create_resources('apache_php::siterename::rename', $sites)
  }

}

define apache_php::siterename::rename (
  $to,
){
  $from = $name

  $vhost_username_old = regsubst($from, '^(.{32})(.*)', '\1')
  exec { "rename site ${vhost_username_old} to ${to}":
    command     => "/usr/local/sbin/renamesite.sh ${vhost_username_old} ${to}",
    onlyif      => "/usr/bin/grep -c ^${vhost_username_old} /etc/passwd",
  }
}