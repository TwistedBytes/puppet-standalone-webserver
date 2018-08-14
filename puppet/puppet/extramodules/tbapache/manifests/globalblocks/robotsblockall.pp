class tbapache::globalblocks::robotsblockall (

) {

  require ::tbapache::globalblocks::robotsblock

  if !defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  file { "${::apache::confd_dir}/01-robotsblockall.conf":
    ensure  => file,
    content => template("${module_name}/globalblocks/robotstxt_blockall.conf.erb"),
    require => Exec["mkdir ${::apache::confd_dir}"],
    notify  => Class['apache::service'],
  }

}