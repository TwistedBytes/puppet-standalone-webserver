class tbphp::fcgi{
  case $::operatingsystem {
    redhat, centos, fedora, Scientific, OracleLinux : { $packagename='fcgi' }
    Debian, Ubuntu : { fail("do no know the name for the fcgi package yet") }
  }

  package { $packagename: ensure => 'latest' }
}