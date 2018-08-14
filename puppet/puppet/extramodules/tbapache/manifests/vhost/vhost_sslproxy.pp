define tbapache::vhost::vhost_sslproxy (
  $vhostname      = undef,
  $priority       = undef,
  $serveraliases  = [],
  $ssl            = undef,
  $options        = { },
  $aliases        = undef,
  $docroot_path   = undef,
  $logroot        = '/var/log/httpd',

) {

  $customfragment = "
  # limit to 100MB request
  LimitRequestBody 102400000

  RequestHeader set X-Forwarded-Protocol https
  RequestHeader set X-Forwarded-Proto https
  RequestHeader set X-Forwarded-Port 443
  ProxyPass / http://${vhostname}/
  ProxyPassReverse / http://${vhostname}/

  "

  $access_log_format = 'vhost_combined_extra'
  $vhostBase = {
    servername        => $vhostname,
    priority          => $priority,
    serveraliases     => $serveraliases,
    docroot           => $docroot_path,
    logroot           => $logroot,
    access_log_file   => "${vhostname}_access.log",
    access_log_format => $access_log_format,
    error_log_file    => "${vhostname}_error.log",
    virtual_docroot   => $virtual_docroot,
    aliases           => $aliases,
    custom_fragment   => join([$customfragment, pick($options['custom'], ' ')], "\n"),
  }

  $vhostConfigPart1 = {

  }

  if ($ssl) and ($ssl['ssl'] == true) {
    $vhostSSL = {
      ssl       => true,
      ssl_key   => $ssl['ssl-key'],
      ssl_cert  => $ssl['ssl-pem'],
      ssl_chain => $ssl['ssl-pem'],
    }


    if ($ssl['ssl-hsts'] == true) {
      # # HTTP Strict Transport Security
      # alleen als alles HTTPS is
      # Nodig voor een A+ in ssllabs, maar verplicht wel alles SSL.
      $vhostSSL['headers'] = ['always set Strict-Transport-Security: "max-age=31536000"']
    }

    $sslHash = merge($vhostBase, $vhostConfigPart1, $vhostSSL, {
      port => '443'
    }
    )
    create_resources('::apache::vhost', {
      "${vhostname}_ssl" => $sslHash
    }
    )
  }

}
