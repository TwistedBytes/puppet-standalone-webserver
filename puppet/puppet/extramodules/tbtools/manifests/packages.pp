define tbtools::packages (
  Array[String] $packages = [],
  $version                = undef,
  Boolean $latest         = true,
  Boolean $refreshonly    = true,
) {

  require ::tbtools::tbpuppetcache

  $package_list = join($packages, ' ')

  file { "${::tbtools::tbpuppetcache::path}/packages-${name}.txt":
    content => $package_list,
    notify  => Exec["mass install packages: ${name}"],
  }

  exec { "mass install packages: ${name}":
    command     => "/usr/bin/yum -y install ${package_list}",
    refreshonly => $refreshonly,
  }
  ->
  package { $packages:
    ensure => $version,
  }


}