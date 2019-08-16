define tbmariadb::db::databasesini (
  $ensure     = 'present',
  $user,
  $database,
  $password,
  $hostname   = 'localhost',
  $ini_file,
  $ini_order  = $name,

) {
  concat::fragment { "database ini ${ini_file} ${database}" :
    target        => $ini_file,
    content       => template("${module_name}/database.ini.erb"),
    order         => "${ini_order}",
  }
}
