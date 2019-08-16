define tbmariadb::grant (
  $ensure     = 'present',
  $user,
  $database,
  $hostname   = "%",
  $privileges = ['ALL'],
  $options    = ['GRANT'],
) {

  mysql_grant { "${user}@${hostname}/${database}.*":
    ensure     => $ensure,
    options    => $options,
    privileges => $privileges,
    table      => "${database}.*",
    user       => "${user}@${hostname}",
    require    => Mysql_user["${user}@${hostname}"],
  }

}