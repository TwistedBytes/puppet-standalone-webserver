class tbapache::mod::geoip {

  case $::operatingsystem {
    redhat, centos, fedora, Scientific, OracleLinux : {
      ensure_packages (['GeoIP-update'])
    }
    default: {
      notify { "no package for geoip database update installed": }
    }
  }

  class { ::apache::mod::geoip:
    enable      => true,
    db_file     => '/usr/share/GeoIP/GeoLiteCountry.dat',
    flag        => 'MemoryCache',
    enable_utf8 => true,


  }
}
