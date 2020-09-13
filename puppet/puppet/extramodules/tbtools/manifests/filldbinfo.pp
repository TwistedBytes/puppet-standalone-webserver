class tbtools::filldbinfo (

) {
  file { "/usr/local/bin/filldbinfo.sh":
    ensure  => 'file',
    content => file("${module_name}/filldbinfo.sh"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { "/usr/local/bin/export-database-info.sh":
    ensure  => 'file',
    content => file("${module_name}/export-database-info.sh"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { "/usr/local/bin/replacevars.sh":
    ensure  => 'file',
    content => file("${module_name}/replacevars.sh"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}