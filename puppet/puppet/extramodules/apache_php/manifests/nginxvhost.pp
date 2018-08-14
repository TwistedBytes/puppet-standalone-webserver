define apache_php::nginxvhost (
  $vhostname     = undef,
  $vhostbase     = undef,
  $priority      = undef,
  $serveraliases = [],
  $uid           = undef,
  $gid           = undef,
  $options       = undef,
  $ssl           = undef,
  $port          = undef,
) {

  $vhostdirs = ["${vhostbase}/site/docroot", "${vhostbase}/logs/web", ]

  file { $vhostdirs:
    ensure => 'directory',
    owner  => $uid,
    group  => $gid,
  }

  if ($options) and ($options['php'] == true) {
    $fastcgi_socket = pick($options['php_fcgi'], undef)

    nginx::resource::upstream { "${vhostname}-php": members => [$fastcgi_socket, ], }
  }

  if ($ssl and $ssl['ssl'] == true) {
    $vhostconfig = "${vhostname}"
  } else {
    $vhostconfig = "${vhostname}_non-ssl"
  }

  ::tbnginx::vhost { $vhostconfig:
    vhostname        => $vhostname,
    vhostbase        => $vhostbase,
    vhostdirs_create => false,
    serveraliases    => $serveraliases,
    uid              => $uid,
    gid              => $gid,
    ssl              => $ssl,
  }

  if ($options) {
    if ($options['php'] == true) {
      if ($options['frameworkconfig'] == 'silverstripe') {
        ::apache_php::nginxvhost::silverstripe { "${vhostconfig}": fastcgi => "${vhostname}-php", }
      }

      ::Tbnginx::Vhost  <| title == $vhostconfig |> {
        enable_php => true,
      }

    }
  }
}

define apache_php::nginxvhost::silverstripe (
  $vhostconfig = $name,
  $fastcgi     = undef
) {
  nginx::resource::location { "${vhostconfig}-ss1":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '^~ /assets/',
    location_custom_cfg => {
      try_files => '$uri =404',
      expires   => 'max',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss2":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ \.ss',
    location_custom_cfg => {
      allow => '127.0.0.1',
      deny  => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss3":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ web\.config',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss4":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ \.(ya?ml|bak|swp)$',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss5":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ ~$',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss6":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '^~ /silverstripe-cache/',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss7":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '^~ /vendor/',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss8":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ /composer\.(json|lock)',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss09":
    vhost               => "${vhostconfig}",
    priority            => 466,
    location            => '~ ^/(cms|framework|mysite)/.+\.(php|php[345]|phtml|inc)$',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss10":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ ^/(cms|framework)/silverstripe_version$',
    location_custom_cfg => {
      deny => 'all',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss11":
    vhost               => "${vhostconfig}",
    priority            => 465,
    location            => '~ ^/framework/(.+/)?(main|rpc|tiny_mce_gzip)\.php$',
    location_custom_cfg => {
      try_files => '/6c1ec1bb21001dd913db95cfb05d78d7.htm @php'
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss12":
    vhost               => "${vhostconfig}",
    priority            => 466,
    location            => '/',
    location_custom_cfg => {
      try_files => '$uri /framework/main.php?url=$uri&$args',
    }
    ,
  }

  nginx::resource::location { "${vhostconfig}-ss13":
    vhost               => "${vhostconfig}",
    priority            => 461,
    location            => '~ ^/(index|install)\.php/',
    fastcgi             => $fastcgi,
    location_cfg_append => {
      fastcgi_split_path_info => '^((?U).+\.php)(/?.+)$',
      fastcgi_param           => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
    }
  }

}
