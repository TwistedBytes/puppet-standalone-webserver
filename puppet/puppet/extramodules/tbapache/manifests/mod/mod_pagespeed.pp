# curl -k --request PURGEMPS 'https://127.0.0.1/*'

class tbapache::mod::mod_pagespeed {

  file { '/etc/httpd/conf.d/pagespeed_libraries.conf':
    ensure  => 'present',
    require => Package[mod-pagespeed-stable],
  }

  class { tbapache::repo::mod_pagespeed: } ->

  package { 'mod-pagespeed-stable':
    ensure  => installed,
    require => Class['Tbapache::Repo::Mod_pagespeed'],
  } ->

  class { apache::mod::pagespeed:
    rewrite_level            => 'PassThrough',
    additional_configuration => {
      'ModPagespeedEnableCachePurge' => 'on',
      'ModPagespeedPurgeMethod'      => 'PURGEMPS',
    }
  }
}
