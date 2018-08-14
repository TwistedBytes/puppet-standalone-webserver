class tbapache::mod::mod_qos {

  package { 'mod_qos':
    ensure  => installed
  } ->

  ::apache::mod { 'unique_id': } ->
  ::apache::mod { 'qos': }  ->

  file { 'qos.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/qos.conf",
    content => template("${module_name}/mod/qos.conf.erb"),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}
