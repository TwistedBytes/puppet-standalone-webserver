define tbmariadb::userandgrant (
  $ensure       = 'present',
  $user         = $name,
  $hostname     = "%",
  $database     = $name,
  $password     = undef,
  $setpassword  = undef,
  $privileges   = undef,
  $my_cnf       = undef,
  $my_cnf_user  = undef,
  $my_cnf_group = undef,

  $pw_context   = $::trusted['certname'],
) {


  if $setpassword != undef and $password == undef {
    $setPassline = tbpassword_setpassword("${pw_context}_${user}", $user, $setpassword)
    $real_password = tbpassword_getpassword("${pw_context}_${user}", $user)
  } else {
    $real_password = $password ? {
      undef   => tbpassword_getpassword("${pw_context}_${user}", $user),
      default => $password
    }
  }

  # notify {"create db user: ${user}@${hostname}": }

  mysql_user { "${user}@${hostname}":
    ensure                   => $ensure,
    password_hash            => mysql_password($real_password),
    max_connections_per_hour => '0',
    max_queries_per_hour     => '0',
    max_updates_per_hour     => '0',
    max_user_connections     => '0',
  }

  if ($ensure == 'present') {
    tbmariadb::grant { "${user}@${hostname}/${database}.*":
      ensure     => $ensure,
      database   => "${database}",
      user       => "${user}",
      privileges => $privileges,
    }
  }

  if ($my_cnf != undef) {
    file { $my_cnf:
      ensure  => $ensure,
      content => template("${module_name}/my.cnf.pass.erb"),
      owner   => $my_cnf_user,
      group   => $my_cnf_user,
      mode    => '0600',
    }
  }


}