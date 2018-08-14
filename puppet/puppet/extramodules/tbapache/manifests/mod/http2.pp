class tbapache::mod::http2 {
  ::apache::mod { 'http2': }

  /*
  package { 'mod_http2':
    ensure  => installed,
    before  => File['http2.conf'],
  } ->
  */

  package { 'libnghttp2':
    ensure => 'latest',
  }

  file { 'http2.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/http2.conf",
    content => template("${module_name}/mod/http2.conf.erb"),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}
