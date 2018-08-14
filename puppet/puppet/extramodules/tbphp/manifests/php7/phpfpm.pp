class tbphp::php7::phpfpm (
  $version           = 'latest',
  $timezone          = 'Europe/Amsterdam',
  $extra_packages    = [],
  $package_prefix    = 'php70-',
  $etc_prefix        = '/etc/opt/remi/php70',
  $var_prefix        = '/var/opt/remi/php70',
  $fpm_pool_dir      = '/etc/opt/remi/php70/php-fpm.d',
  $socket_switch_dir = '/var/run/php-fpm7-switcher',
) {

  class { tbphp::php7::packages:
    version        => $version,
    package_prefix => $package_prefix,
    extra_packages => $extra_packages,
  }

  tbphp::php7::pool { 'php7-www':
    ensure           => 'present',
    pm               => 'ondemand',
    listen           => "${var_prefix}/run/php-fpm/www.sock",
    listen_backlog   => 65535,
    pm_start_servers => 0,
  }

  class { tbphp::php7::service:

  }

  php::config::setting { "${package_prefix}expose_php":
    key     => 'PHP/expose_php',
    file    => "${$etc_prefix}/php.ini",
    value   => 'Off',
    require => Package["${package_prefix}php-common"],
  }

  php::config::setting { "${package_prefix}php_timezone":
    file    => "${$etc_prefix}/php.d/05-timezone.ini",
    key     => 'date.timezone',
    value   => $timezone,
    require => Package["${package_prefix}php-common"],
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
  } ~> Class['tbphp::php7::service']

}
