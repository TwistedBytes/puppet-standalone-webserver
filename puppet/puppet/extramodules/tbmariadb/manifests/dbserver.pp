class tbmariadb::dbserver (
  $dbs                     = {},
  $update_to_utf8mb4       = true,
  $master_slave            = undef, # can be undef, master, slave, galera
  $bindip                  = '0.0.0.0',
  $mysqld_options          = {},
  $temp_root_pw            = undef,
  $backup_enable           = true,
  $backuptype              = undef,
  $mariadb_version         = '10.0',
  $charset                 = 'utf8mb4',
  $collate                 = undef,
  $mysqltype               = 'mariadb',
  $galera                  = {},
  $root_pw_context         = $::trusted['certname'],
  $gtid_domain_id          = 1,
  $gtid_domain_id_hash     = {},
  $enable_encryption       = false,
  $ssl_config              = false,
  $ssl_config_san          = [],
  $ssl_config_ipsan        = [],
  $ssl_clients             = [],
  $ssl_clients_require_ssl = true,
) {

  $password_salt = cache_data('mysql_password_salt', $root_pw_context, fqdn_rand_string(64))

  case $mysqltype {
    'mariadb': {
      $mysqlname = 'mariadb'
      $dbservicename = 'mariadb'

      $dbuser = 'mysql'
      $dbgroup = 'mysql'
      $run_dir = '/var/run/mariadb'
      $log_dir = '/var/log/mariadb'
      $data_dir = '/var/lib/mysql'

      $dbdirs = [$run_dir, $log_dir]

      $error_log = "${log_dir}/${mysqlname}.log"
      $slow_log = "${log_dir}/${mysqlname}-slow.log"
      $pid_file = "${run_dir}/${mysqlname}.pid"

      $repo_class = 'tbmariadb::repo'
      case $::osfamily {
        'RedHat': {
          case $::operatingsystem {
            /^(RedHat|CentOS)$/: {
              $package_name_server = 'MariaDB-server'
              $package_name_client = "MariaDB-client"

              $config_file = '/etc/my.cnf'
              $includedir = '/etc/my.cnf.d'
            }
          }
        }
        'Debian': {
          $package_name_server = "mariadb-server"
          $package_name_client = "mariadb-client"

          $config_file = '/etc/mysql/my.cnf'
          $includedir = '/etc/mysql/conf.d'
        }
      }
    }
    'percona': {
      $package_name_server = 'Percona-Server-server-57'
      $package_name_client = "Percona-Server-client-57"

      $config_file = '/etc/my.cnf'
      $includedir = '/etc/my.cnf.d'

      $mysqlname = 'mysql'
      $dbservicename = 'mysql'

      $dbuser = 'mysql'
      $dbgroup = 'mysql'
      $run_dir = "/run/${mysqlname}"
      $log_dir = "/var/log/${mysqlname}"
      $data_dir = '/var/lib/mysql'

      $dbdirs = [$run_dir, $log_dir]

      $error_log = "${log_dir}/${mysqlname}.log"
      $slow_log = "${log_dir}/${mysqlname}-slow.log"
      $pid_file = "${run_dir}/${mysqlname}.pid"

      $repo_class = 'tbmariadb::repo::percona'
    }
  }

  include $repo_class

  file { $dbdirs:
    ensure  => 'directory',
    owner   => $dbuser,
    group   => $dbgroup,
    before  => [ Service[$dbservicename], ],
    require => Package['mysql-server'],
  }

  tbsystemd::tmpfiles { "mariadb-rundir":
    content      => "d ${run_dir} 0755 ${dbgroup} ${dbgroup}",
    file         => "${mysqlname}-rundir.conf",
    file_replace => true,
  }


  if $temp_root_pw != undef {
    $root_password = $temp_root_pw
  } else {
    $root_password = cache_data('mysql_root_pw', $root_pw_context, fqdn_rand_string(25))
  }

  $real_collate = $collate ? {
    undef   => "${charset}_unicode_ci",
    default => $collate,
  }

  $mysqld_override_options = {
    query_cache_size               => '32M',
    innodb_buffer_pool_size        => '256M',
    innodb_file_per_table          => 'ON',
    character-set-client-handshake => 'FALSE',
    character-set-server           => $charset,
    collation-server               => $real_collate,
    max_connections                => 600,
    wait_timeout                   => 3600,
    interactive_timeout            => 3600,
    tmp_table_size                 => '64M',
    max_heap_table_size            => '64M',
    max_allowed_packet             => '64M',
    log-error                      => $error_log,
    slow_query_log_file            => $slow_log,
    pid-file                       => $pid_file,
    slow_query_log                 => 1,
    long_query_time                => 5,
    bind-address                   => $bindip,
  }

  if $enable_encryption or $ssl_config {
    $encryption_dir = '/etc/mysql_encryption'

    file { $encryption_dir:
      ensure => 'directory',
      mode   => "0700",
      owner  => $dbuser,
      group  => $dbgroup,
    }
  }

  if $enable_encryption {
    tbmariadb::server::encryptionkeys { "keyfile":
      before => Class['Mysql::Server']
    }

    $override_encryption_options = {
      plugin_load_add                          => 'file_key_management',
      file_key_management_filename             => "${encryption_dir}/keyfile.enc",
      file_key_management_filekey              => "FILE:${encryption_dir}/keyfile.key",
      file_key_management_encryption_algorithm => 'AES_CTR',

      innodb_default_encryption_key_id         => 1,
      encrypt_binlog                           => true,
      innodb_encrypt_log                       => true,
      innodb_encrypt_tables                    => "FORCE",
      innodb_encryption_threads                => 4,
      encrypt_tmp_disk_tables                  => true,
      encrypt_tmp_files                        => true,
    }
  } else {
    $override_encryption_options = {}
  }

  if $ssl_config {
    file { ["${encryption_dir}/ssl", "${encryption_dir}/ssl/clients"]:
      ensure  => 'directory',
      mode    => "0700",
      owner   => $dbuser,
      group   => $dbgroup,
      backup  => false,
      recurse => true,
      purge   => true,
    }

    tbopensslca::cacerts { $::trusted['certname']:
      tbopensslcacontext => "${$::trusted['certname']}-mysql",
      basepath           => "${encryption_dir}/ssl",
      certname           => $::trusted['certname'],
      san                => concat([$::trusted['certname']], $ssl_config_san),
      sanip              => concat(["127.0.0.1", "::1", "${::facts['network_primary_ip']}"], $ssl_config_san),
      owner              => $dbuser,
      group              => $dbgroup,
      before             => Class['Mysql::Server']
    }

    $ssl_clients.each |Integer $index, String $value| {
      tbopensslca::clientcerts { $value:
        tbopensslcacontext => "${::trusted['certname']}-mysql",
        basepath           => "${encryption_dir}/ssl/clients",
        certname           => $value,
        owner              => 'root',
        group              => 'root',
        before             => Class['Mysql::Server']
      }
    }

    # tbopensslca_revokecrt("${$::trusted['certname']}-mysql", $::trusted['certname'])

    $override_ssl_options = {
      ssl      => true,
      ssl-ca   => "${encryption_dir}/ssl/${$::trusted['certname']}.ca.crt",
      ssl-cert => "${encryption_dir}/ssl/${$::trusted['certname']}.crt",
      ssl-key  => "${encryption_dir}/ssl/${$::trusted['certname']}.key",
      ssl-crl  => "${encryption_dir}/ssl/${$::trusted['certname']}.crl.pem",
    }

    $mysql_client_ssl_options = {
      ssl-ca   => "${encryption_dir}/ssl/${$::trusted['certname']}.ca.crt",
      ssl-cert => "${encryption_dir}/ssl/${$::trusted['certname']}.crt",
      ssl-key  => "${encryption_dir}/ssl/${$::trusted['certname']}.key",
    }

    if ($ssl_clients_require_ssl) {
      Mysql_user <| title != "sensucheck@%" |> {
        tls_options => 'SSL',
      }
    }

  } else {
    $override_encrpytion_options = {}
    $mysql_client_ssl_options = {}
  }

  $mysql_client_override = deep_merge2($mysql_client_ssl_options, {})

  if $master_slave == undef {
    $override_master_slave_options = {}
  } elsif $master_slave == 'galera' {
    $override_master_slave_options = {}
  } else {
    if $master_slave == 'master' {
      include tbmariadb::master
    }
    $override_master_slave_options = {
      bind-address                   => $bindip,
      server-id                      => cache_data('mysql_server_id', $::trusted['certname'], fqdn_rand(400000000, $password_salt)),
      gtid_domain_id                 => $gtid_domain_id,
      binlog-format                  => 'MIXED',
      log-bin                        => "${mysqlname}-bin",
      relay-log                      => "${mysqlname}-relay-bin",
      datadir                        => $data_dir,
      innodb_flush_log_at_trx_commit => '1',
      sync_binlog                    => '1',
    }
  }

  if $backuptype == 'mysqlbackupbinlog' {
    $mysqld_binlog_options = {
      server-id     => cache_data('mysql_server_id', $::trusted['certname'], fqdn_rand(400000000, $password_salt)),
      log-bin       => "${mysqlname}-bin",
      binlog_format => 'MIXED',
      sync_binlog   => '5',
    }
  } else {
    $mysqld_binlog_options = {}
  }

  if $master_slave == 'galera' {

    $status_password = cache_data('mysql_status_pw', $root_pw_context, fqdn_rand_string(25))

    if ($gtid_domain_id_hash[$::trusted['certname']]) {
      $real_gtid_domain_id = $gtid_domain_id_hash[$::trusted['certname']]
    } else {
      $real_gtid_domain_id = $gtid_domain_id
    }

    $override_options = deep_merge2($mysqld_override_options, $mysqld_binlog_options, $override_encryption_options,
      $override_ssl_options, $override_master_slave_options, $mysqld_options, {
        gtid_domain_id     => $real_gtid_domain_id,
        binlog_format      => 'ROW',
        wsrep_cluster_name => "wsrep_${galera['clustername']}"
      })

    class { 'galera':
      galera_servers        => $galera['servers'],
      galera_master         => $galera['master'],
      galera_package_ensure => 'installed',
      mysql_service_name    => $dbservicename,

      bind_address          => $galera['bind_address'],
      status_password       => $status_password,
      status_allow          => 'localhost',

      vendor_type           => 'mariadb', # default is 'percona'
      vendor_version        => '10.3',

      local_ip              => $galera['localip'],
      # This will be used to populate my.cnf values that control where wsrep binds, advertises, and listens
      root_password         => $root_password, # This will be set when the cluster is bootstrapped
      configure_repo        => false, # Disable this if you are managing your own repos and mirrors
      configure_firewall    => false, # Disable this if you don't want firewall rules to be set

      override_options      => {
        'mysqld' => $override_options
      },
    }

  } else {

    class { 'mysql::server':
      root_password    => $root_password,
      override_options => {
        'mysqld' => deep_merge2($mysqld_override_options, $mysqld_binlog_options, $override_encryption_options,
          $override_ssl_options, $override_master_slave_options, $mysqld_options),
        'client' => $mysql_client_override,
      },
      service_name     => $dbservicename,
      package_name     => $package_name_server,
      service_enabled  => true,
      config_file      => $config_file,
      includedir       => $includedir,
      purge_conf_dir   => true,
      require          => Class[$repo_class]
    }

  }

  File <| title == 'mysql-config-file' |> {
    notify => [Service[$dbservicename]],
  }

  if $update_to_utf8mb4 {
    class { tbmariadb::converttoutf8mb4:
      breadcrumb => "${includedir}/updated-to-utf8mb4",
      require    => Class['mysql::server'],
    }
  }

  $backup_ensure = $backup_enable ? {
    true  => 'present',
    false => 'absent',
  }

  class { ::tbmariadb::server::backup:
    backup_ensure => $backup_ensure,
    backuptype    => $backuptype,
    pwcontext     => $root_pw_context,
  }

  Package <| title == 'mysql-server' |> {
    notify => [Exec["mysql-upgrade"]],
  }

  class { 'mysql::client':
    package_name => $package_name_client,
    require      => [Class[$repo_class], Class['mysql::server']],
  }

  exec { "mysql-upgrade":
    command     => "mysql_upgrade --force",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    require     => Service[$dbservicename],
    refreshonly => true,
  }

  class { 'tbmariadb::mytop': }

  include ::mysql::server::account_security
  class { '::tbmariadb::server::mysqltuner':
    version => '1.7.13',
  }

  validate_hash($dbs)

  create_resources('apache_php::db', $dbs,
    {
      pw_context => $root_pw_context,
    }
  )

  tbinfluxdata::checks::procstat { "mysqld":
    pattern => "/usr/sbin/mysqld",
    stats   => true,
  }

  tbinfluxdata::apps::cgroup_slice { "mysql":
    cgrouppath => "system.slice/mysql.service",
  }

  tbinfluxdata::apps::mysql { $::trusted['certname']:
    pwcontext => $root_pw_context,
  }

}
