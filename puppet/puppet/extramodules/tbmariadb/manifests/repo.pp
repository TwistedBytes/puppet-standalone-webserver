class tbmariadb::repo (
  $version = '10.0',
) {
  case $::osfamily {

    'Debian': {
      if $::operatingsystem == 'Ubuntu' and $::lsbmajdistrelease == '16.04' and $version == '10.0' {

      } else {
        class { tbmariadb::repo::apt:
          mariadb_version => $version
        }
      }
    }

    'RedHat': {
      class { tbmariadb::repo::yum:
        mariadb_version => $version
      }
    }

    default: { fail("${::osfamily} not supported yet") }

  }
}