class tbmariadb::haproxy::check (
  $service_name   = 'mysql-haproxy-check',
  $install_path   = '/opt/mysql_haproxy_check',
  $service_ensure = 'running',
  $service_enable = true,
) {

  include ::systemd

  if $::operatingsystem == 'Debian' and $::lsbmajdistrelease == '8' {
    $systemdbasedir = '/etc/systemd/system'
  } else {
    $systemdbasedir = '/usr/lib/systemd/system'
  }

  package { ['MySQL-python']: ensure => 'installed', }

  file { "${systemdbasedir}/${service_name}.service":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/mysql_haproxy_check/systemd.erb"),
  } ~>
  Exec['systemctl-daemon-reload']


  file { "${install_path}":
    ensure => directory,
    owner   => 'root',
    group   => 'root',
  }

  file { "${install_path}/mysql_haproxy_check.py":
    content => template("${module_name}/mysql_haproxy_check/mysql_haproxy_check.py"),
    notify  => Service[$service_name],
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
  }

  service { $service_name:
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => [File["${systemdbasedir}/${service_name}.service"], Package['MySQL-python']]
  }

}