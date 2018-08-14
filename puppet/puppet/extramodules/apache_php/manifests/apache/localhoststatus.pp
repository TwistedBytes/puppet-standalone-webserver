class apache_php::apache::localhoststatus (
  $vhostprio   = 99,
  $listen_port = 80,
  $listen_ip   = undef,
) {
  $vhostname = 'localhost'

  $port = hiera('apache_php::varnish_used::port', $listen_port)

  ::apache::vhost { "localhost-status":
    servername        => $vhostname,
    ip                => $listen_ip,
    port              => $port,
    docroot           => '/var/www/vhosts/localhost',
    access_log_file   => "${vhostname}_access.log",
    access_log_format => 'vhost_combined_extra',
    error_log_file    => "${vhostname}_error.log",
    priority          => $vhostprio,
  }

  class { 'apache::mod::status':
  }

  tbinfluxdata::apps::apache { 'apache':
    statusurl => "http://${vhostname}:${port}//server-status?auto"
  }
}
