class tbapache::mod::evasive (
  $DOSHashTableSize  = 3097,
  $DOSPageCount      = 3,
  $DOSSiteCount      = 100,
  $DOSPageInterval   = 1,
  $DOSSiteInterval   = 1,
  $DOSBlockingPeriod = 10,
  $DOSEmailNotify    = undef,
  $DOSWhitelist      = [],
) {

  ::apache::mod { 'evasive':
    id   => 'evasive20_module',
    path => 'modules/mod_evasive24.so'
  }

  ensure_packages(['mod_evasive'])

  file { 'evasive.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/evasive.conf",
    content => template("${module_name}/mod/evasive.conf.erb"),
    require => [Class['apache'], Exec["mkdir ${::apache::mod_dir}"]],
    notify  => Class['apache::service'],
  }

  file { '/var/lock/mod_evasive':
    ensure => directory,
    owner  => 'apache',
    group  => 'apache',
    mode   => '0700',
  }
}
