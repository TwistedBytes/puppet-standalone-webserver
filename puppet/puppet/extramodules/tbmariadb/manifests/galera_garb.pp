class tbmariadb::galera_garb (
  $clustername,
  $servers,
) {
  class { 'galera_arbitrator':
    galera_nodes => join(suffix($servers, ':4567'), ' '),
    # galera_nodes => join($servers, ' '),
    galera_group => $clustername,
    packagename  => 'galera',
  }

  file { "/var/lib/garb":
    ensure => 'directory',
    owner  => 'nobody',

  }

  include ::tbsystemd::detect
  if $::tbsystemd::detect::systemdpresent {
    tbsystemd::servicefile { 'garb_workingdir':
      servicename => 'garb.service',
      filename    => 'garb_workingdir',
      content     => {
        'Service' => {
          'WorkingDirectory' => '/var/lib/garb',
        }
      },
      require     => Class['::galera_arbitrator'],
    }
  }

}