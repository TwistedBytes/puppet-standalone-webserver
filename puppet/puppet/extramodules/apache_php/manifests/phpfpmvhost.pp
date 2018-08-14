define apache_php::phpfpmvhost (
  $ensure                  = 'present',
  $vhostname               = undef,
  $listen                  = undef,
  $vhostbase               = undef,
  $runasuid                = undef,
  $runasgid                = undef,
  $pmdefaults              = undef,
  $request_slowlog_timeout = 20,
  $php_values_override     = {},
  $unix_socket_group       = $::apache::params::group,
  $create_dirs             = true,
  $php7                    = false,
  $php7_switcher_replace   = false,
) {
  $real_pmdefaults = $pmdefaults ? {
    undef   => hiera_hash('apache_php::phpfpmvhost::pmdefaults'),
    default => $pmdefaults,
  }

  $php_values_default = {
    php_admin_value => {
      'date.timezone'     => 'Europe/Amsterdam',
      'error_log'         => "${vhostbase}/logs/php/${vhostname}-error.log",
      'session.save_path' => "${vhostbase}/private/php-sessions",
      'upload_tmp_dir'    => "${vhostbase}/private/php-tmp",
      # 'open_basedir'      => ".:/usr/share/pear:/usr/share/php:${vhostbase}", do not use. It's a CPU hog
    },
    php_admin_flag  => {
    },
    php_value       => {
      'error_reporting'     => 'E_ALL & ~E_NOTICE & ~E_DEPRECATED',
      'upload_max_filesize' => '250M',
      'post_max_size'       => '250M',
      'max_execution_time'  => '600',
      'memory_limit'        => '256M',
      'output_buffering'    => '1M',
    },
    php_flag        => {
      'display_errors' => 'off',
      'log_errors'     => 'on',
    }
  }

  $php_values_default_override_global = hiera('apache_php::phpfpmvhost::php_values_override', {})

  $php_values_default_merged = deep_merge($php_values_default, $php_values_default_override_global, $php_values_override)

  $pool_defaults = {
    ensure                    => $ensure,
    listen                    => $listen,
    user                      => $runasuid,
    group                     => $runasgid,
    listen_group              => $unix_socket_group,
    listen_mode               => '0666',
    listen_backlog            => 65535,
    security_limit_extensions => ['.php .php3 .php4 .php5'],
    slowlog                   => "${vhostbase}/logs/php/${vhostname}-slow.log",
    catch_workers_output      => 'yes',
    request_slowlog_timeout   => $request_slowlog_timeout,
    pm                        => pick($real_pmdefaults['pm'], 'ondemand'),
    pm_start_servers          => pick($real_pmdefaults['pm_start_servers'], 2),
    pm_min_spare_servers      => pick($real_pmdefaults['pm_min_spare_servers'], 2),
    pm_max_spare_servers      => pick($real_pmdefaults['pm_max_spare_servers'], 5),
    pm_max_children           => pick($real_pmdefaults['pm_max_children'], 20),
    pm_max_requests           => pick($real_pmdefaults['pm_max_requests'], 1000),
    pm_process_idle_timeout   => pick($real_pmdefaults['pm_process_idle_timeout'], '30s'),
    pm_status_path            => $real_pmdefaults['pm_status_path'],
    php_admin_value           => $php_values_default_merged['php_admin_value'],
    php_admin_flag            => $php_values_default_merged['php_admin_flag'],
    php_value                 => $php_values_default_merged['php_value'],
    php_flag                  => $php_values_default_merged['php_flag'],
  }

  $php5_overrides = hiera_hash('apache_php::phpfpmvhost::pmdefaults::php5', {})

  $enablephp56 = hiera('apache_php::phpfpmvhost::php56', true)
  if $enablephp56 {
    create_resources(php::fpm::pool, { "${vhostname}" => $php5_overrides }, $pool_defaults)
  }

  if ($php7) {
    case $php7 {
      /^\d+$/, 70, 71, 72, 73: {
        $php7version = $php7
      }
      true: {
        $php7version = 70
      }
    }

    require ::tbphp::php7x::data

    $php7_listen = regsubst($listen, '^/var(.*)$', "${::tbphp::php7x::data::var_prefix}${php7version}\\1")

    $php7_overrides = {
      phpversion         => $php7version,
      'listen'           => $php7_listen,
      'slowlog'          => "${vhostbase}/logs/php/${vhostname}-php7-slow.log",
      'php_admin_value'  => merge($pool_defaults['php_admin_value'], {
        'error_log' => "${vhostbase}/logs/php/${vhostname}-php7-error.log",
      }),
      before             => Service["php${php7version}-php-fpm"],
      switchfile_replace => $php7_switcher_replace
    }

    if $php7version == 70 {
      create_resources(tbphp::php7::pool, { "${vhostname}" => $php7_overrides }, $pool_defaults)
    } else {
      create_resources(tbphp::php7x::pool, { "${vhostname}" => $php7_overrides }, $pool_defaults)
    }

    if $real_pmdefaults['pm_status_path'] {
      tbinfluxdata::apps::phpfpmpool { $vhostname:
        poolname       => $vhostname,
        socket         => $php7_listen,
        pm_status_path => regsubst($real_pmdefaults['pm_status_path'], '^.(.*)$', '\1'),
      }
    }

  }

  if ($create_dirs) {
    if ($ensure == 'present') {
      $vhostdirs = ["${vhostbase}/private/php-tmp", "${vhostbase}/private/php-sessions", "${vhostbase}/logs/php", ]

      file { $vhostdirs:
        ensure => 'directory',
        owner  => $runasuid,
        group  => $runasgid,
      }
    }
  }
}
