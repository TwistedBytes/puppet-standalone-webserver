# == Class: php::fpm::pool
#
# Configure fpm pools
#
# === Parameters
#
# No parameters
#
# === Authors
#
# Christian "Jippi" Winther <jippignu@gmail.com>
# Robin Gloster <robin.gloster@mayflower.de>
#
# === Copyright
#
# See LICENSE file
#
define tbphp::php7::pool (
  $phpversion = "70",
  $ensure = 'present',
  $listen = '127.0.0.1:9000',
  # Puppet does not allow dots in variable names
  $listen_backlog = '-1',
  $listen_allowed_clients = '127.0.0.1',
  $listen_owner = undef,
  $listen_group = undef,
  $listen_mode = undef,
  $user = $php::fpm::config::user,
  $group = $php::fpm::config::group,
  $pm = 'dynamic',
  $pm_max_children = '50',
  $pm_start_servers = '5',
  $pm_min_spare_servers = '5',
  $pm_max_spare_servers = '35',
  $pm_process_idle_timeout = '30s',
  $pm_max_requests = '0',
  $pm_status_path = undef,
  $ping_path = undef,
  $ping_response = 'pong',
  $request_terminate_timeout = '0',
  $request_slowlog_timeout = '0',
  $security_limit_extensions = undef,
  $slowlog = "${tbphp::php7::phpfpm::var_prefix}/log/php-fpm/${name}-slow.log",
  $rlimit_files = undef,
  $rlimit_core = undef,
  $chroot = undef,
  $chdir = undef,
  $catch_workers_output = 'no',
  $env = [],
  $env_value = { },
  $php_value = { },
  $php_flag = { },
  $php_admin_value = { },
  $php_admin_flag = { },
  $php_directives = [],
  $error_log = true,

  $switchfile_replace        = false,
) {

  $pool = $name

  # Hack-ish to default to user for group too
  $group_final = $group ? { undef => $user, default => $group }

  if ($ensure == 'absent') {
    file { "${tbphp::php7::phpfpm::fpm_pool_dir}/${pool}.conf":
      ensure => absent,
      notify => Class['tbphp::php7::service'],
    }
  } else {
    file { "${tbphp::php7::phpfpm::fpm_pool_dir}/${pool}.conf":
      ensure  => file,
      notify  => Class['tbphp::php7::service'],
      require => Package["${tbphp::php7::phpfpm::package_prefix}php-fpm"],
      content => template('php/fpm/pool.conf.erb'),
      owner   => root,
      group   => root,
      mode    => '0644'
    }

    $socket_basename = basename($listen)
    tbsystemd::tmpfiles { "php7-switcher-pool-${pool}":
      content      => "L ${tbphp::php7::phpfpm::socket_switch_dir}/${socket_basename} 0666 root apache - ${listen}",
      file         => "php7-switcher-pool-${pool}.conf",
      file_replace => $switchfile_replace,
    }

  }

}
