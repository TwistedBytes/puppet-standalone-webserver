class tbmariadb::repo::apt (
  $mariadb_version    = '10.1',
){

  $distro = downcase($::operatingsystem)

  apt::source { 'MariaDB':
    ensure      => $ensure,
    location    => "http://mariadb.mirror.triple-it.nl/repo/${mariadb_version}/${distro}",
    release     => $::lsbdistcodename,
    repos       => 'main',
    include     => { 'src' => false },
    key         => {
      id => '177F4010FE56CA3336300305F1656F24C74CD1D8',
    }
  }

}