define tbapache::vhost::vhost_custom (
  $vhostname     = undef,
  $priority      = undef,
  $serveraliases = [],
  $ssl           = undef,
  $options       = {},
  $aliases       = undef,
  $docroot_path  = undef,
  $logroot       = '/var/log/httpd',
  $ensure        = 'present',
) {
  $varnish_port = hiera('apache_php::varnish_used::port', undef)

  $customfragment = "
  # limit to 100MB request
  LimitRequestBody 102400000
    "

  $vhostBase = {
    servername        => $vhostname,
    priority          => $priority,
    serveraliases     => $serveraliases,
    docroot           => $docroot_path,
    logroot           => $logroot,
    access_log_file   => "${vhostname}_access.log",
    error_log_file    => "${vhostname}_error.log",
    access_log_format => 'vhost_combined_extra',
    aliases           => $aliases,
    custom_fragment   => join([$customfragment, pick($options['custom'], ' ')], "\n"),
    ensure            => $ensure,
  }

  $vhostConfigPart1 = {

  }

  $port = $varnish_port ? {
    undef   => 80,
    default => $varnish_port,
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