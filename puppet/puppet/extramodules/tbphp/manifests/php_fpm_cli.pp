define tbphp::php_fpm_cli (
  $ensure       = 'present',
  $tmpdir,
  $gid          = 'root',
  $uid          = 'root',
  $phpfpmsocket = '/var/run/php5-fpm.sock',
){

  require tbphp::fcgi

  file { "${title}":
    ensure  => $ensure,
    owner   => $uid,
    group   => $gid,
    mode    => '0700',
    content => template("${module_name}/php-fpm-cli.erb"),
  }

}