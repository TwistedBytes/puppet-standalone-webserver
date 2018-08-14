class tbphp::php7::packages (
  $version        = 'latest',
  $extra_packages = [],
  $package_prefix = 'php70-',
){

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
  $phpversion = $version

  $prefixed_packages = prefix($phppackages, $package_prefix)

  package { $prefixed_packages:
    ensure  => $phpversion,
    require => Yum::Managed_yumrepo['remi'],
  }


}