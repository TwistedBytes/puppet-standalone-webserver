define apache_php::apachevhostssl (
  $serveraliases = undef,
  $vhostBase,
  $vhostConfigPart1,
  $port,
  $ssl,
  $priority      = undef,
) {
  $vhostname = $name

  $vhostBase_real = merge($vhostBase, {
    priority      => $priority,
    servername    => $vhostname,
    serveraliases => $serveraliases,
  })

  $ssl_port = $ssl['port'] ? {
    undef   => 443,
    default => $ssl['port'],
  }

  if $vhostBase['ip'] != undef {
    $nvh_addr_port = "${vhostBase['ip']}:${ssl_port}"
    ensure_resource('apache::listen', $nvh_addr_port)
  }

  $vhostSSL1 = {
    ssl => true,
  }

  $le_newpath = hiera('apache_php::apachevhostssl::le_newpath', false)

  if ($le_newpath) {
    $le_path = '/etc/ssl/le-puppet'
  } else {
    $le_path = '/etc/letsencrypt.sh/live/certs'
  }

  if $ssl['letsencrypt'] {
    $letsdomains = $ssl['letsencrypt-domains'] ? {
      undef   => delete_undef_values(flatten([$vhostname, $serveraliases])),
      default => $ssl['letsencrypt-domains'],
    }

    Tbletsencrypt::Certonly <| |> -> Class['Apache::Service']

    $_letsdnslogin = $ssl['letsencrypt-dnslogin'] ? {
      undef   => "",
      default => $ssl['letsencrypt-dnslogin'],
    }

    tbletsencrypt::certonly { $vhostname:
      domains  => $letsdomains,
      dnslogin => $_letsdnslogin,
    }

    $vhostSSL2 = {
      ssl_key   => "${le_path}/${vhostname}/privkey.pem",
      ssl_cert  => "${le_path}/${vhostname}/cert.pem",
      ssl_chain => "${le_path}/${vhostname}/chain.pem",
    }
  } elsif $ssl['certs'] {
    $sslparts = ::tbsite::certparts($ssl['certs'])

    $vhostSSL2 = {
      ssl_key   => $sslparts['key'],
      ssl_cert  => $sslparts['cert'],
      ssl_chain => $sslparts['fullchain'],
    }
  } else {
    $vhostSSL2 = {
      ssl_key   => $ssl['ssl-key'],
      ssl_cert  => $ssl['ssl-crt'],
      ssl_chain => $ssl['ssl-chain'],
    }
  }

  if ($ssl['redirectnon-ssl']) and $ssl['redirectnon-ssl'] != false {
    if ($ssl['redirectnon-ssl-hostname']) {
      $ssl_redirect_hostname = $ssl['redirectnon-ssl-hostname']
    } else {
      $ssl_redirect_hostname = '%{HTTP_HOST}'
    }
    if ($ssl['redirectnon-ssl-letsencrypt'] or $ssl['letsencrypt']) {
      $ssl_rewrite_cond = ['%{HTTPS} off', '%{HTTP:X-Forwarded-Proto} !https', '%{REQUEST_URI} !^/.well-known/acme-challenge/']
    } else {
      $ssl_rewrite_cond = ['%{HTTPS} off', '%{HTTP:X-Forwarded-Proto} !https']
    }

    $ssl_redirect_type = $ssl['redirectnon-ssl-type'] ? {
      302     => ' [R=302,L]',
      default => ' [R=301,L]',
    }

    $vhostRedirectToSSL = {
      rewrites => [{
        comment      => 'redirect toSSL',
        rewrite_cond => $ssl_rewrite_cond,
        rewrite_rule => ["(.*) https://${ssl_redirect_hostname}%{REQUEST_URI}${ssl_redirect_type}"],
      }
        , ]
    }
    if ($ssl['redirectnon-ssl'] == true) {
      if ($ssl['redirectnon-ssl-http-custom']) {
        $nonssl_custom = join($ssl['redirectnon-ssl-http-custom'])

        Concat::Fragment <|  title == "${vhostname}_non-ssl-custom_fragment" |> {
          order => 185,
        }
      } else {
        $nonssl_custom = ''
      }

      $nonSslHash = merge($vhostBase_real, $vhostRedirectToSSL, {
        port            => $port,
        custom_fragment => $nonssl_custom,
      })
    } elsif ($ssl['redirectnon-ssl'] == 'proxy') {
      $nonSslHash = merge($vhostBase_real, $vhostConfigPart1, $vhostRedirectToSSL, {
        port => $port
      })
    }
  } else {
    $nonSslHash = merge($vhostBase_real, $vhostConfigPart1, {
      port => $port,
    })
  }

  if ($ssl['ssl-hsts'] == true) {
    # # HTTP Strict Transport Security
    # alleen als alles HTTPS is
    # Nodig voor een A+ in ssllabs, maar verplicht wel alles SSL.
    $vhostSSL3 = {
      headers => ['always set Strict-Transport-Security: "max-age=31536000"']
    }
  } else {
    $vhostSSL3 = {}
  }
  if($ssl['ssl-varnish-proxy']) {
    include ::tbnginx::vhost_ssl_proxy_defaultsite

    if $ssl['letsencrypt'] {
      $ssl1 = {
        ssl     => true,
        ssl-key => "${le_path}/${vhostname}/privkey.pem",
        ssl-pem => "${le_path}/${vhostname}/fullchain.pem",
      }

      Tbletsencrypt::Certonly <| |> -> Class['::nginx::service']
    } else {
      $ssl1 = $ssl
    }

    ::tbnginx::vhost_ssl_proxy { "${vhostname}_ssl":
      vhostname          => $vhostname,
      serveraliases      => $serveraliases,
      ssl                => $ssl1,
      proxy_read_timeout => '600',
    }
  } else {
    $vhostSSL = merge($vhostSSL1, $vhostSSL2, $vhostSSL3)
    $sslHash = merge($vhostBase_real, $vhostConfigPart1, $vhostSSL, {
      port => $ssl_port
    })
    create_resources('::apache::vhost', {
      "${vhostname}_ssl" => $sslHash
    })
  }

  create_resources('::apache::vhost', {
    "${vhostname}_non-ssl" => $nonSslHash,
  })
}