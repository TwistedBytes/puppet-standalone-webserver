class apache_php::dbclean (
  $user      = 'derk',
  $database  = 'derk',
  $password  = 'derkderkderk',
){
  mysql_database { "${user}":
    ensure  => 'absent',
  }

  mysql_user { "${user}@localhost":
    ensure  => 'absent',
  }

  mysql_grant { "${user}@localhost/${database}.*":
    ensure  => 'absent',
    table   => "${database}.*",
    user    => "${user}@localhost",
  }
}
