define tbsystemd::service (
  $content = { },
  $ensure = 'present',
){
  $servicename = $name

  include ::systemd

  $dir = "/etc/systemd/system"

  file { "${dir}/${servicename}.service":
    ensure  => $ensure,
    content => template("${module_name}/systemd.any.erb"),
    owner   => 'root',
    group   => 'root',
    notify  => Exec["systemctl-daemon-reload", "systemctl-restart ${servicename}"],
  }

  exec { "systemctl-restart ${servicename}":
    command     => "/usr/bin/systemctl restart ${servicename}",
    require     => Exec["systemctl-daemon-reload"],
    refreshonly => true,
  }

}