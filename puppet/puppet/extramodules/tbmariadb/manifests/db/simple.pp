define tbmariadb::db::simple (
  $ensure       = 'present',
  $password     = undef,
  $tbpw_context = "${::fqdn}_mysql",
  $ini_file     = undef,
  $usergrant    = undef,
  $charset      = 'utf8mb4',
  $collate      = undef,
  $privileges   = undef,
  $ini_order    = $name,

  $import_ini   = undef,
) {

  if $import_ini != undef {
    Tbmariadb::Db::Databasesini <<| tag == "${name}-${import_ini}"  |>> {
      ensure    => $ensure,
      ini_file  => $ini_file,
      ini_order => $ini_order,
    }

  } else {

    $database = "${name}"
    $database_user = $usergrant ? {
      undef   => $database,
      default => $usergrant,
    }

    $realpassword = $password ? {
      undef   => tbpassword_getpassword($tbpw_context, $database_user),
      default => $password,
    }

    # notify{$realpassword:}

    tbmariadb::db { $database_user:
      ensure     => $ensure,
      user       => $database_user,
      database   => $database,
      password   => $realpassword,
      ini_file   => $ini_file,
      usergrant  => $usergrant,
      charset    => $charset,
      collate    => $collate,
      privileges => $privileges,
      ini_order  => $ini_order,
    }
  }
}
