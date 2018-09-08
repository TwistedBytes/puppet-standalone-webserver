# ssl hash:git clone https://github.com/TwistedBytes/puppet-standalone-webserver.git

#{
#   ssl => true,
#   redirectnon-ssl => false
#   ssl-key => 'path on server'
#   ssl-pem => 'path on server'
#   ssl-hsts => true/false #
#}

define apache_php::apachevhost (
  $vhostname      = undef,
  $vhostbase      = undef,
  $priority       = undef,
  $serveraliases  = [],
  $uid            = undef,
  $gid            = undef,
  $ssl            = undef,
  $options        = undef,
  $aliases        = undef,
  $followsymlinks = 'SymLinksIfOwnerMatch',
  $docroot_name         = 'site/docroot',
  $docroot_create       = true,
  $docroot_mode         = '0755',
  $virtual_docroot_name = 'docroot',
  $virtualdocroot       = false,
  $create_logdir        = true,
  $proxy_timeout        = 600,
  $log_format_name      = undef,
  $ssl_alts             = undef,
  $ip                   = undef,
  $replace_config_var   = false,
  $custom               = [],
  $htpasswdfile         = undef,
  $cleanheaders         = false,
) {
  include ::apache::version
  $apache_version      = $::apache::version::default

  $logroot = pick(hiera('apache_php::apachevhost::logroot', undef), "${vhostbase}/logs/web")

  $varnish_port = hiera('apache_php::varnish_used::port', undef)
  $port = $varnish_port ? {
    undef   => 80,
    default => $varnish_port,
  }

  if ($create_logdir){
    file { "${vhostbase}/logs/web":
      ensure => 'directory',
      owner  => $uid,
      group  => $gid,
    }
  }

  if $virtualdocroot {
    $access_log_format = 'cvhost_combined_extra'
    $docroot_path  = "${vhostbase}/domains"
    $virtual_docroot = "${vhostbase}/domains/%0/${virtual_docroot_name}"

    file { "${vhostbase}/domains":
      ensure => 'directory',
      owner  => $uid,
      group  => $gid,
      mode   => $docroot_mode,
    }

    $vhost_require = []
  } else {
    $access_log_format = 'vhost_combined_extra'
    $virtual_docroot = $virtualdocroot
    $docroot_path  = "${vhostbase}/${docroot_name}"

    if $docroot_create {
      if ($options) and ($options['docroot_symlink'] == true) {
        if $options['link_to'] {
          file { $docroot_path:
            ensure => 'link',
            target => $options['link_to'],
            owner  => $uid,
            group  => $gid,
          }
        } else {
          file { $docroot_path:
            owner => $uid,
            group => $gid,
          }
        }
      } else {
        file { $docroot_path:
          ensure => 'directory',
          owner  => $uid,
          group  => $gid,
          mode   => $docroot_mode,
        }
      }
    }

    $vhost_require = File[$docroot_path]

  }

  $log_format = $log_format_name ? {
    undef   => $access_log_format,
    default => $log_format_name,
  }

  $addlisten = $ip ? {
    undef => true,
    default => false,
  }

  if $ip != undef {
    $nvh_addr_port = "${ip}:${port}"
    ensure_resource('apache::listen', $nvh_addr_port)
  }

  $vhostBase = {
    servername         => $vhostname,
    priority           => $priority,
    ip                 => $ip,
    add_listen         => $addlisten,
    serveraliases      => $serveraliases,
    docroot            => $docroot_path,
    require            => $vhost_require,
    logroot            => $logroot,
    access_log_file    => "${vhostname}_access.log",
    access_log_format  => $log_format,
    error_log_file     => "${vhostname}_error.log",
    virtual_docroot    => $virtual_docroot,
  }

  if ($options) and ($options['blockrobots'] == true) {
    require ::tbapache::globalblocks::robotsblock
    $norobots = template("tbapache/globalblocks/robotstxt_blockall.conf.erb")
  } else {
    $norobots = undef
  }

  if ($options) and ($options['php'] == true) {
    $fastcgi_socket = pick($options['php_fcgi'], undef)
    $apachenew = hiera('apache_php::apachenew', false)

    if($apachenew){
      $custom1 = "
  # PHP requests to php-fpm
  ProxyTimeout ${proxy_timeout}
  SetEnvIfNoCase X-Forwarded-Proto https HTTPS=on
  <FilesMatch '\\.php$'>
      # disable httpoxy, https://httpoxy.org/
      RequestHeader unset Proxy early
      SetHandler  'proxy:${fastcgi_socket}'
  </FilesMatch>
      "
    } else {
      $custom1 = "
  # PHP requests to php-fpm
  # disable httpoxy, https://httpoxy.org/
  RequestHeader unset Proxy early
  ProxyTimeout ${proxy_timeout}
  SetEnvIfNoCase X-Forwarded-Proto https HTTPS=on
  ProxyPassMatch ^/(.*\\.php(/.*)?)$ ${fastcgi_socket}${$docroot_path}/\$1
      "
    }

    $custom2 = "
  # limit to 100MB request
  LimitRequestBody 102400000
    "

    $customfragment = join(delete_undef_values([$custom1, $custom2, ' ']), "\n")

  } else {
    $customfragment = "
  # limit to 100MB request
  LimitRequestBody 102400000
    "
  }

  if versioncmp($apache_version, '2.4') < 0 {
    $dir_custom_fragment = ''
  } else {
    $dir_custom_fragment = 'CGIPassAuth On'
  }

  if $htpasswdfile != undef {
    $passwordprotect = "
    <Directory ${docroot_path}>
      <If \"-f '${vhostbase}/${htpasswdfile}'\">
        AuthType Basic
        AuthName 'Restricted'
        # (Following line optional)
        AuthBasicProvider file
        AuthUserFile '${vhostbase}/${htpasswdfile}'
        Require valid-user
      </If>
    </Directory>
    "
  } else {
    $passwordprotect = undef
  }

  if $cleanheaders == true {
    $_cleanheaders = '
    Header always unset "X-Powered-By"
    Header unset "X-Powered-By"
    '
  } else {
    $_cleanheaders = undef
  }


  $pre_real_customfragment = join(delete_undef_values(concat([$customfragment, $norobots, $passwordprotect, $_cleanheaders, pick($options['custom'], undef)], $custom)), "\n")

  if $replace_config_var {
    $real_customfragment01 = regsubst($pre_real_customfragment, '{##VAR_DOCROOT##}', $docroot_path, 'G' )
    $real_customfragment = regsubst($real_customfragment01, '{##VAR_VHOSTBASE##}', $vhostbase, 'G' )
  } else {
    $real_customfragment = $pre_real_customfragment
  }

  $vhostConfigPart1 = {
    custom_fragment => $real_customfragment,
    aliases         => $aliases,
    directories     => [{
      provider        => 'directory',
      path            => $docroot_path,
      options         => [$followsymlinks],
      allow_override  => [
        'AuthConfig',
        'Limit',
        'FileInfo',
        'Indexes',
        'Options',
      ],
      directoryindex  => 'index.html index.php',
      custom_fragment => $dir_custom_fragment,
    }
    ],
  }

  if ($ssl == undef) or ($ssl['ssl'] == false) {
    $nonSslHash = merge($vhostBase, $vhostConfigPart1, {
      port => $port,
    })

    create_resources('::apache::vhost', {
      "${vhostname}_non-ssl" => $nonSslHash,
    })
  } else {
    apache_php::apachevhostssl { $vhostname:
      serveraliases    => $serveraliases,
      port             => $port,
      priority         => $priority,
      ssl              => $ssl,
      vhostBase        => $vhostBase,
      vhostConfigPart1 => $vhostConfigPart1,
    }

    if ($ssl_alts != undef) {
      validate_hash($ssl_alts)

      create_resources('apache_php::apachevhostssl', $ssl_alts, {
        port             => $port,
        vhostBase        => $vhostBase,
        vhostConfigPart1 => $vhostConfigPart1,
      })
    }
  }
}
