class tbmariadb::master (
  $ensure = 'present',
  $otherserver = []) {

  $replication_password = cache_data('mysql_replication_pw', $::fqdn, sha1(String(fqdn_rand(1230000000000))))

  # notify {"replicationpassword: ${$replication_password}":}

  mysql_user { 'replication@%':
    ensure        => $ensure,
    password_hash => mysql_password($replication_password)
  }

  mysql_grant { 'replication@%/*.*':
    ensure     => $ensure,
    options    => ['GRANT'],
    privileges => ['REPLICATION SLAVE'],
    table      => "*.*",
    user       => 'replication@%',
    require    => Mysql_user['replication@%'],
  }
}
