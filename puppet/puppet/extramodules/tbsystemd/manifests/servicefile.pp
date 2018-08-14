define tbsystemd::servicefile (
  $servicename,
  $filename,
  $content = {},
) {

  include ::systemd

  $dir = "/etc/systemd/system/${servicename}.d"

  if !defined(File["${dir}"]) {
    file { $dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }
  }

  file { "${dir}/${filename}.conf":
    ensure  => present,
    content => template("${module_name}/systemd.any.erb"),
    owner   => 'root',
    group   => 'root',
    notify  => Exec["systemctl-daemon-reload", "systemctl-restart ${servicename} $filename"],
  }

  exec { "systemctl-restart ${servicename} $filename":
    path        => $::path,
    command     => "systemctl restart ${servicename}",
    require     => Exec["systemctl-daemon-reload"],
    refreshonly => true,
  }

}