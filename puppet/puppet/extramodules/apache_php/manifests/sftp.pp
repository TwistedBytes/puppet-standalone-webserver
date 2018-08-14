class apache_php::sftp (
) {
  class { 'ssh::server':
    permit_root_login    => 'yes',
    subsystem_sftp       => 'internal-sftp',
    print_motd           => 'yes',
    allow_tcp_forwarding => 'yes'
  }

}
