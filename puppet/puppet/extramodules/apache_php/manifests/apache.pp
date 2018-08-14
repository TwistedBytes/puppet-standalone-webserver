class apache_php::apache (
  $createdefaultsite        = false,
  $mpm                      = 'event',
  $keepalive                = 'On',
  $keepalive_timeout        = 15,
  $timeout                  = 1200,
  $max_keepalive_requests   = 100,
  $event_serverlimit        = 25,
  $event_maxclients         = 600,
  $event_maxrequestworkers  = 250,
  $letsencrypt              = true,
  $expires                  = true,

  $ssl_protocol             = ['all', '-SSLv2', '-SSLv3'],
  $ssl_cipher               = 'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS',
) {

  require ::tbapache

  include ::apache::version

  class { '::tbapache::tools::clean_shared_mem': }

  $apache_version      = $::apache::version::default

  $apachenew = hiera('apache_php::apachenew', true)
  if($apachenew){
    require ::tbsite::twistedbtyesrepo
    Class['::tbsite::twistedbtyesrepo'] -> Class['::apache']
  }

  if versioncmp($apache_version, '2.4') < 0 {
    $extra_mods1 = ['proxy_fcgi']
    $apache_log_timeformat = {
      vhost_combined        => '%v %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
      cvhost_combined_extra => '%V:%p %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Forwarded-For}i\" %I %O %X %D (%{ratio}n%%)', # Canonical version
      vhost_combined_extra  => '%v:%p %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Forwarded-For}i\" %I %O %X %D (%{ratio}n%%)',
    }
  } else {
    $extra_mods1 = ['proxy_fcgi', 'access_compat', 'remoteip']
    $apache_log_timeformat = {
      vhost_combined        => '%v %h %l %u [%{%d/%b/%Y:%T}t.%{msec_frac}t %{%z}t] \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
      cvhost_combined_extra => '%V:%p %h %l %u [%{%d/%b/%Y:%T}t.%{msec_frac}t %{%z}t] \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Forwarded-For}i\" %I %O %X %D (%{ratio}n%%)', # Canonical version
      vhost_combined_extra  => '%v:%p %h %l %u [%{%d/%b/%Y:%T}t.%{msec_frac}t %{%z}t] \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Forwarded-For}i\" %I %O %X %D (%{ratio}n%%)',
    }
  }

  if $::osfamily == 'RedHat' {
    $apache_service_restart = "apachectl graceful"
  } else {
    $apache_service_restart = undef
  }

  class { '::apache':
    package_ensure         => 'latest',
    mpm_module             => false,
    server_tokens          => 'Prod',
    server_signature       => 'Off',
    keepalive              => $keepalive,
    keepalive_timeout      => $keepalive_timeout,
    max_keepalive_requests => $max_keepalive_requests,
    timeout                => $timeout,
    log_formats            => $apache_log_timeformat,
    vhost_dir              => '/etc/httpd/vhosts.d',
    default_vhost          => false,
    default_mods           => concat([
      'mime', 'mime_magic', 'rewrite', 'ext_filter', 'headers', 'dir', 'auth_digest', 'auth_basic', 'authn_core',
      'authn_file', 'authz_groupfile', 'authz_user', 'info', 'status', 'logio', 'alias', 'setenvif',
      'env', 'proxy', ], $extra_mods1),
    service_restart => $apache_service_restart,
  }

  if $expires {
    class { '::apache::mod::expires':
      expires_active  => 'On',
      expires_by_type => {
        'text/html'                     => "access plus 1 hour",
        'text/plain'                    => "access plus 1 hour",
        'application/rss+xml'           => "access plus 1 month",
        'text/css'                      => "access plus 1 month",
        'application/javascript'        => "access plus 1 month",
        'text/javascript'               => "access plus 1 month",
        'image/x-icon'                  => "access plus 1 month",
        'image/vnd.microsoft.icon'      => "access plus 1 month",
        'image/gif'                     => "access plus 1 month",
        'image/png'                     => "access plus 1 month",
        'image/jpg'                     => "access plus 1 month",
        'image/jpeg'                    => "access plus 1 month",
        'video/ogg'                     => "access plus 1 month",
        'audio/ogg'                     => "access plus 1 month",
        'video/mp4'                     => "access plus 1 month",
        'audio/mpeg'                    => "access plus 1 month",
        'video/webm'                    => "access plus 1 month",
        'text/x-component'              => "access plus 1 month",
        'font/truetype'                 => "access plus 1 month",
        'font/opentype'                 => "access plus 1 month",
        'application/x-font-woff'       => "access plus 1 month",
        'application/font-woff'         => "access plus 1 month",
        'image/svg+xml'                 => "access plus 1 month",
        'application/vnd.ms-fontobject' => "access plus 1 month",
      }
    }
  }

  # these are loaded anyway in default_mods
  # log_config systemd authz_host authz_core filter

  case $mpm {
    'event'  : {
      class { "::apache::mod::event":
        maxclients        => $event_maxclients,
        threadsperchild   => '50',
        maxrequestworkers => $event_maxrequestworkers,
        serverlimit       => $event_serverlimit,
      }
    }
    'worker' : {
      class { "::apache::mod::worker": }
    }
  }

  # https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
  class { 'apache::mod::ssl':
    ssl_compression => false,
    ssl_options     => ['StdEnvVars'],
    ssl_protocol    => $ssl_protocol,
    ssl_cipher      => $ssl_cipher,
  }

  class { '::apache::mod::deflate':
    types => [
      'text/html text/plain',
      'text/xml image/svg+xml',
      'text/css',
      'application/font-woff application/x-font-woff font/truetype font/opentype',
      'application/x-javascript text/javascript',
      'application/javascript',
      'application/json'
    ],
  }

  file { "${::apache::httpd_dir}/localconf.d":
    ensure  => 'directory',
    mode    => '0711',
    owner   => 'root',
    group   => 'root',
    require => Class['::apache'],
  }

}
