class tbsite::backup::backupdir (

){

  file { '/var/backup':
    ensure => 'directory',
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }

}