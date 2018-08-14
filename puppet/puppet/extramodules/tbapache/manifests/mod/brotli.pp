class tbapache::mod::brotli {
  ::apache::mod { 'brotli': }

  /*
  package { 'mod_http2':
    ensure  => installed,
    before  => File['http2.conf'],
  } ->
  */

  file { 'brotli.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/brotli.conf",
    content => template("${module_name}/mod/brotli.conf.erb"),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}
