class tbsystemd::detect {

  case $::osfamily {
    'RedHat': {
      if ($::operatingsystem == 'CentOS' and versioncmp($::operatingsystemmajrelease, '7') >= 0) {
        $systemdpresent = true
      } else {
        $systemdpresent = false
      }
    }
  }
}