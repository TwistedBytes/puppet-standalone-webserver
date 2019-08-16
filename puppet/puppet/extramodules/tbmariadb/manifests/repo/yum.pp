class tbmariadb::repo::yum (
  $mariadb_version    = '10.0',
){

  $releasever = '$releasever'

  yum::managed_yumrepo { 'MariaDB':
    descr         => 'MariaDB from MariaDB repos',
    baseurl       => "https://yum.mariadb.org/${mariadb_version}/centos${releasever}-amd64",
    enabled       => 1,
    gpgcheck      => 0,
    gpgkey_source => "puppet:///modules/${module_name}/mariadb/RPM-GPG-KEY-MariaDB",
    priority      => 1,
    autokeyimport => 'yes',
  }

}