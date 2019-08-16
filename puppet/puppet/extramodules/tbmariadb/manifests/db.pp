define tbmariadb::db (
  $user       = $name,
  $hostname   = "%",
  $database   = $name,
  $password   = undef,
  $usergrant  = undef,
  $ini_file   = undef,
  $charset    = 'utf8mb4',
  $collate    = undef,
  $privileges = undef,
  $ensure     = 'present',
  $ini_order  = $name,
) {

  $real_colate = $collate ? {
    undef   => "${charset}_unicode_ci",
    default => $collate,
  }

  mysql_database { "${database}":
    ensure  => $ensure,
    charset => $charset,
    collate => $real_colate,
  }

  if ($usergrant != undef) {
    tbmariadb::grant { "${user}@${hostname}/${database}.*":
      ensure     => $ensure,
      database   => $database,
      user       => $user,
      privileges => $privileges,
    }

  } else {

    ::tbmariadb::userandgrant { "${user}@${hostname}":
      ensure     => $ensure,
      user       => $user,
      database   => $database,
      password   => $password,
      privileges => $privileges,
    }
  }
}
