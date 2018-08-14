class tbphp::packageonly (
  $versions = ['70'],
  $linkphp = '70',
) {

  ::tbphp::php7x::packages { $versions:
  }

  if is_numeric($linkphp) == true {
    file { "/usr/bin/php":
      ensure  => 'link',
      target  => "/usr/bin/php${linkphp}",
      require => ::Tbphp::Php7x::Packages[$linkphp],
    }
  }


}