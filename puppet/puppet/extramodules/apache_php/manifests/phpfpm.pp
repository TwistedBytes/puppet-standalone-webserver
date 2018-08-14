class apache_php::phpfpm (
  $version        = undef,
  $timezone       = 'Europe/Amsterdam',
  $extra_packages = [],
  $update_php     = true,
  $composer       = true,
) {
  if $update_php {
    include 'yum::repo::remi'
    include 'yum::repo::remi_php56'

    Class['yum::repo::remi'] -> Class['yum::repo::remi_php56']

    $require_repo = Yum::Managed_yumrepo['remi-php56']
    $new_packages = ["php-mysqlnd",]
  } else {
    $require_repo = undef
    $new_packages = ["php-mysql",]
  }

  $phppackages = concat ([
    "php-bcmath",
    "php-dba",
    "php-gd",
    "php-gmp",
    "php-imap",
    "php-intl",
    "php-ldap",
    "php-mbstring",
    "php-mcrypt",
    "php-odbc",
    "php-pdo",
    "php-pgsql",
    "php-process",
    "php-pspell",
    "php-soap",
    "php-tidy",
    "php-xml",
    "php-xmlrpc",
    "php-opcache",
    "php-pecl-zip",
  ], $new_packages, $extra_packages)
  $phpversion = $version

  package { $phppackages:
    ensure  => $phpversion,
    require => $require_repo,
  }

  Package <| title == 'php' |> {
    ensure => 'absent',
  }

  class { '::php':
    ensure       => $phpversion,
    manage_repos => false,
    dev          => false,
    composer     => $composer,
    pear         => false,
    phpunit      => false,
    fpm          => false,
    require      => $require_repo,
    settings     => {
      'PHP/expose_php'          => 'Off',
      'Date/date.timezone'      => $timezone,
    },
  }

  class { '::php::fpm':
    ensure => $phpversion,
    pools  => {
      'www' => {
        ensure            => 'present',
        pm                => 'ondemand',
        listen            =>'/var/run/php-fpm/www.sock',
        listen_backlog    => 65535,
        pm_start_servers  => 0,
      }
    }
  ,
  }

  # automatic clean up php-fpm config
  File <| title == $php::params::fpm_pool_dir |> {
    recurse => true,
    purge   => true,
    notify  => Class['php::fpm::service'],
  }

}
