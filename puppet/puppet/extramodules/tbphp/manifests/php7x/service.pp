define tbphp::php7x::service (
  $ensure = 'running',
  $enable = true,
) {
  $phpversion = $name
  $service_name = "php${phpversion}-php-fpm"

  service { $service_name:
    ensure    => $ensure,
    enable    => $enable,
    restart   => "service ${service_name} reload",
    hasstatus => true,
    require   => Package["php${phpversion}-php-fpm"],
  }
}
