class tbtools::assetsdbto (

) {
  require ::tbtools::filldbinfo

  file { "/usr/local/bin/assetsdbto2.sh":
    ensure  => 'file',
    content => file("${module_name}/assetsdbto.sh"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  ensure_packages(['pv'], {
    ensure => 'installed',
  })
}