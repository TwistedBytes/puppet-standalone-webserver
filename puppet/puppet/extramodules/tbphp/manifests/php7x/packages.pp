define tbphp::php7x::packages (
  $version        = 'latest',
  $extra_packages = [],
){
  include 'yum::repo::remi'

  $phpversion     = $name
  $package_prefix = "php${phpversion}-"

  $phppackages = concat ([
    "php-common",
    "php-bcmath",
    "php-dba",
    "php-gd",
    "php-gmp",
    "php-imap",
    "php-intl",
    "php-ldap",
    "php-mbstring",
    "php-mcrypt",
    "php-mysqlnd",
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
    "php-fpm",
    "php-cli",
    "php-pecl-zip",
  ], $extra_packages)

  $prefixed_packages = prefix($phppackages, $package_prefix)

  package { $prefixed_packages:
    ensure  => $version,
    require => Yum::Managed_yumrepo['remi'],
  }


}