class tbsite::twistedbtyesrepo (
  $addtest = false,
) {
  yum::managed_yumrepo { 'twistedbtyesrepo':
    descr    => 'twistedbtyes centos 7 repo',
    baseurl  => 'http://repository.twistedbytes.eu/centos/$releasever/',
    enabled  => 1,
    gpgcheck => 0,
    priority => 1,

  }

  if $addtest {
    yum::managed_yumrepo { 'twistedbtyesrepo-test':
      descr    => 'twistedbtyes centos 7 repo test',
      baseurl  => 'http://repository.twistedbytes.eu/centos/$releasever-test/',
      enabled  => 1,
      gpgcheck => 0,
      priority => 1,
    }

  } else {
    file { "/etc/yum.repos.d/twistedbtyesrepo-test.repo":
      ensure => 'absent',
    }
  }
}
