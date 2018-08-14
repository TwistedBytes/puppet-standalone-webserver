define apache_php::allinone (
  $ensure              = 'present',
  $vhostname,
  $vhostbase,
  $username,
  $priority            = 25,
  $docroot_name        = 'site/docroot',
  $docroot_create      = true,
  $serveraliases       = undef,
  $pmdefaults          = undef,
  $php_values_override = undef,
  $options             = {},
  $ssl                 = undef,
  $ssl_alts            = undef,
  $proxy_timeout       = undef,
  $ip                  = undef,
  $log_format_name     = undef,
  $custom              = [],
) {

  $usephp = pick($options['php'], true)
  $phptype = pick($options['phptype'], 'php')
  $php7 = pick($options['php7'], false)

  $fcgi_listen = "/var/run/php-fpm/${vhostname}.sock"

  if $php7 {
    require ::tbphp::php7X::phpswitcher

    $php7_switcher_fcgi_listen = "${tbphp::php7x::phpswitcher::socket_switch_dir}/${vhostname}.sock"
    file { $php7_switcher_fcgi_listen:
      ensure  => 'link',
      replace => false,
      target  => $fcgi_listen,
    }
    $apache_fcgi = "unix:${php7_switcher_fcgi_listen}|fcgi://${vhostname}"
  } else {
    $apache_fcgi = "unix:${fcgi_listen}|fcgi://${vhostname}"
  }

  $_fulldocroot = "${vhostbase}/${docroot_name}"

  if !defined(Tbsite::Mkdir::Mkdir_p[$_fulldocroot]) {
    ::tbsite::mkdir::mkdir_p { $_fulldocroot: }
    $parentdirs = parentdirs($_fulldocroot, $vhostbase)
    file { $parentdirs:
      owner => $username,
      group => $username,
      mode  => '0751',
    }
  }

  if ($ensure == 'present') {
    apache_php::apachevhost { "$vhostname@${::fqdn}":
      vhostname       => $vhostname,
      ip              => $ip,
      serveraliases   => $serveraliases,
      priority        => $priority,
      vhostbase       => $vhostbase,
      uid             => $username,
      gid             => $username,
      docroot_name    => $docroot_name,
      docroot_create  => $docroot_create,
      log_format_name => $log_format_name,
      ssl             => $ssl,
      ssl_alts        => $ssl_alts,
      options         => {
        php             => $usephp,
        php_fcgi        => $apache_fcgi,
        frameworkconfig => pick($options['frameworkconfig'], 'none'),
        custom          => pick($options['custom'], ' '),
      },
      proxy_timeout   => 14400,
      custom          => $custom,
    }
  }

  if ($usephp == true) {
    if $phptype == 'php' {
      apache_php::phpfpmvhost { "$vhostname@${::fqdn}":
        ensure                  => $ensure,
        vhostname               => $vhostname,
        listen                  => $fcgi_listen,
        vhostbase               => $vhostbase,
        runasuid                => $username,
        runasgid                => $username,
        pmdefaults              => $pmdefaults,
        php_values_override     => $php_values_override,
        create_dirs             => false,
        request_slowlog_timeout => pick($options['php_request_slowlog_timeout'], 20),
        php7                    => $php7,

      }
    }
  }


}