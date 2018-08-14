class apache_php::apache::redisadmin (
  $version      = '1.4.1',
  $dl_path      = undef,
  $install_path = "/var/www/vhosts/TB01-001/comprensys01.example.com/site/docroot",
  $url_path     = 'tb-phpra',
  $username     = 'admin',
  $password     = undef,
) {

  if $password == undef {
    $password_real = tbpassword_getpassword("${::fqdn}_redisadmin", $username)
  } else {
    $password_real = $password
  }

  $real_dlpatch = $dl_path ? {
    undef => "https://github.com/ErikDubbelboer/phpRedisAdmin/archive/v${version}.zip",
    default => $dl_path,
  }

  staging::deploy { "phpRedisAdmin-${version}.zip":
    source  => $real_dlpatch,
    target  => $install_path,
    creates => "${install_path}/phpRedisAdmin-${version}",
    onlyif  => undef,
    notify  => Exec["composer redisadmin"],
    require => [Package['unzip']],
  } ->

  exec { "composer redisadmin":
    command     => "/usr/local/bin/composer install",
    cwd         => "${install_path}/phpRedisAdmin-${version}",
    environment => ["COMPOSER_HOME=${install_path}/phpRedisAdmin-${version}",],
    refreshonly => true,
  } ->
  file { "${install_path}/phpRedisAdmin-${version}":
    ensure  => directory,
  } ->

  file { "${install_path}/phpRedisAdmin-${version}/includes/config.inc.php":
    ensure  => present,
    content => template('apache_php/phpredisadmin/config.inc.php.erb'),
  } ->
  file { "${install_path}/phpRedisAdmin-${version}/.htaccess":
    ensure  => present,
    content => template('apache_php/phpredisadmin/htaccess.erb'),
  } ->

  # need for php docroot
  file { "${install_path}/${url_path}":
    ensure => 'link',
    target => "phpRedisAdmin-${version}",
  }
}