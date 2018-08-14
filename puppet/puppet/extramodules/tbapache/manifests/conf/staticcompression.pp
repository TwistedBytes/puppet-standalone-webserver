class tbapache::conf::staticcompression {

  file { 'staticcompression.conf':
    ensure  => file,
    path    => "${::apache::confd_dir}/staticcompression.conf",
    content => template("${module_name}/conf/staticcompression.conf.erb"),
    require => Exec["mkdir ${::apache::confd_dir}"],
    before  => File[$::apache::confd_dir],
    notify  => Class['apache::service'],
  }
}
