class tbmariadb::repo::percona (

) {

  $releasever = '$releasever'

  yum::managed_yumrepo { 'Percona':
    descr         => 'CentOS $releasever - Percona',
    baseurl       => 'https://repo.percona.com/percona/yum/release/$releasever/RPMS/x86_64',
    enabled       => 1,
    gpgcheck      => 1,
    gpgkey        => 'https://repo.percona.com/percona/yum/PERCONA-PACKAGING-KEY',
    priority      => 1,
    autokeyimport => 'yes',
  }

}
