class tbapache::globalblocks::blockdotfilesdirectories (

){

  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  file { 'zz-blockdotfilesdirectories.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/zz-blockdotfilesdirectories.conf",
    content => template("${module_name}/globalblocks/blockdotfilesdirectories.conf.erb"),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}