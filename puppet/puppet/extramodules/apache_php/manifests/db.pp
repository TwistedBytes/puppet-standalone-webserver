define apache_php::db (
  $user            = $name,
  $database        = $name,
  $password        = undef,
  $setpassword     = undef,
  $usergrant       = undef,
  $ini_file        = undef,
  $charset         = 'utf8mb4',
  $collate         = undef,
  $privileges      = undef,
  $ensure          = 'present',
  $ini_order       = $name,

  $export_ini      = false,
  $export_hostname = undef,
) {


  $realpassword = $password ? {
    undef   => tbpassword_getpassword("${::trusted['certname']}_mysql", $user),
    default => $password,
  }

  tbmariadb::db { $name:
    ensure     => $ensure,
    user       => $user,
    database   => $database,
    password   => $realpassword,
    usergrant  => $usergrant,
    charset    => $charset,
    collate    => $collate,
    privileges => $privileges,
  }

  if ($ini_file != undef) {
    apache_php::db::databasesini { "database ini ${ini_file} ${database}":
      user      => $user,
      database  => $database,
      password  => $realpassword,
      ini_file  => $ini_file,
      ini_order => $ini_order,
    }
  }

}
