class tbphp::php7x::phpswitcher (
  $socket_switch_dir = '/var/run/php-fpm7-switcher',
  $switcher_path     = '/usr/local/bin/php-version-switcher.sh',
) {

  tbsystemd::tmpfiles { "php7-switcher-rundir":
    content      => "d ${socket_switch_dir} 0755 root root",
    file         => '00php7-switcher-rundir.conf',
    file_replace => true,
  }

  file { $socket_switch_dir:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    recurse => true,
    purge   => true,
  }

  file { $switcher_path:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => "puppet:///modules/${module_name}/php-version-switcher.sh",
  }


}