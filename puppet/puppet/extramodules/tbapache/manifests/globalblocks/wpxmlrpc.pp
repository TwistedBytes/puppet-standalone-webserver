class tbapache::globalblocks::wpxmlrpc (

){

  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  file { 'wpcxmlrpcblock.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/wpcxmlrpcblock.conf",
    content => template("${module_name}/globalblocks/wpcxmlrpcblock.conf.erb"),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}