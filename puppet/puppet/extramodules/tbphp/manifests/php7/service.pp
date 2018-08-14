class tbphp::php7::service (
  $service_name = 'php70-php-fpm',
  $ensure       = 'running',
  $enable       = $php::params::fpm_service_enable,
) inherits php::params {

  service { $service_name:
    ensure    => $ensure,
    enable    => $enable,
    restart   => "service ${service_name} reload",
    hasstatus => true,
    require   => Package['php70-php-fpm'],
  }
}
