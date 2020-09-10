define tbphp::php7x::phpfpm (
  $version  = 'latest',

) {
  $phpversion = $name
  $extra_packages = hiera('tbphp::php7x::phpfpm::extra_packages', [])

  $timezone = hiera('tbphp::php7x::phpfpm::timezone', 'Europe/Amsterdam')
  $customconfig = hiera('tbphp::php7x::phpfpm::customconfig', undef)

  require ::tbphp::php7x::data

  $package_prefix = "php${phpversion}-"
  $etc_prefix = "${tbphp::php7x::data::etc_prefix}${phpversion}"
  $var_prefix = "${tbphp::php7x::data::var_prefix}${phpversion}"
  $fpm_pool_dir = "${::tbphp::php7x::data::fpm_pool_dir_pre}${phpversion}${::tbphp::php7x::data::fpm_pool_dir_post}"

  if !defined(Tbphp::Php7x::Packages[$phpversion]) {
    tbphp::php7x::packages { $phpversion:
      extra_packages => $extra_packages,
    }
  }

  if !defined(Tbphp::Php7x::Service[$phpversion]) {
    tbphp::php7x::service {$phpversion:}
  }

  tbphp::config::setting { "${package_prefix}expose_php":
    key     => 'PHP/expose_php',
    file    => "${etc_prefix}/php.ini",
    value   => 'Off',
    require => Package["${package_prefix}php-common"],
  } ~> Tbphp::Php7x::Service[$phpversion]

  tbphp::config::setting { "${package_prefix}php_timezone":
    file    => "${etc_prefix}/php.d/05-timezone.ini",
    key     => 'date.timezone',
    value   => $timezone,
    require => Package["${package_prefix}php-common"],
  } ~> Tbphp::Php7x::Service[$phpversion]

  if $customconfig != undef {
    file { "${etc_prefix}/php.d/99-custom.ini":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      content => $customconfig,
      require => Package["${package_prefix}php-common"],
    } ~> Tbphp::Php7x::Service[$phpversion]
  }

  # automatic clean up php-fpm config
  file { $fpm_pool_dir:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    recurse => true,
    purge   => true,
    require => [Package["${package_prefix}php-fpm"]],
  } ~> Tbphp::Php7x::Service[$phpversion]

}
