class tbapache::globalblocks::robotsblock (

) {

  if !defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  file { '/var/www/robots/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/var/www/robots/blockall-robots.txt':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/robots_blockall.txt",
  }
}