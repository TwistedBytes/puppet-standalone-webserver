class tbapache::log::globallog (
  $logroot = $::apache::logroot,
) {

  if ! defined(Class['apache']) {
  fail('You must include the apache base class before using any apache defined resources')
}

file { '00-globallog.conf':
  ensure  => file,
  path    => "${::apache::confd_dir}/00-globallog.conf",
  content => template("${module_name}/globallog.conf.erb"),
  notify  => Class['apache::service'],
}
}