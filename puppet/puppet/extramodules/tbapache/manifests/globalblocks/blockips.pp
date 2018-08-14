class tbapache::globalblocks::blockips (

){

  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  file { 'zz-blockips.conf':
    ensure  => file,
    path    => "${::apache::confd_dir}/00-blockips.conf",
    content => template("${module_name}/globalblocks/blockips.conf.erb"),
    notify  => Class['apache::service'],
    replace => false,
  }
}