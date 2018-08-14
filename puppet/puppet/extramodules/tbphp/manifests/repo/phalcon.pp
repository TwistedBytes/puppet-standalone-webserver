class tbphp::repo::phalcon (

){

  case $::osfamily {
    'RedHat', 'Linux': {
      notify {"not supported yet": }
    }
    'Debian': {

      $location = 'https://packagecloud.io/phalcon/stable/debian/'
      apt::source { 'phalcon_stable':
        ensure         => 'present',
        location       => $location,
        release        => $::lsbdistcodename,
        repos          => main,
        include        => { 'src' => false },
        key         => {
          id      => '418A7F2FB0E1E6E7EABF6FE8C2E73424D59097AB',
          source  => 'https://packagecloud.io/phalcon/stable/gpgkey',
        }
      }

    }
  }

}