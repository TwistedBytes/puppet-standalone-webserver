# See README.me for usage.
class tbmariadb::server::mysqlbackupbinlog (
  $backupuser         = '',
  $backuppassword     = '',
  $backupdir          = '',
  $backupdirmode      = '0700',
  $backupdirowner     = 'root',
  $backupdirgroup     = $mysql::params::root_group,
  $backupcompress     = true,
  $backuprotate       = 7, # keep how many full backups
  $ignore_events      = true,
  $delete_before_dump = false,
  $backupdatabases    = [],
  $file_per_database  = false,
  $include_triggers   = false,
  $include_routines   = false,
  $ensure             = 'present',
  $time_full          = ['23', '5', '*', '*', '0'],
  $time_flush         = ['*/1', '10', '*', '*', '*'],
  $prescript          = false,
  $postscript         = false,
  $execpath           = '/usr/bin:/usr/sbin:/bin:/sbin',
  $logbinbasename     = '/var/lib/mysql/mariadb-bin',
  $maxallowedpacket   = '512M',
  $clusterbackup      = undef,
) {

  mysql_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql_password($backuppassword),
    require       => Class['mysql::server::root_password'],
  }

  $privs = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS', 'TRIGGER', 'SUPER', 'REPLICATION CLIENT' ]

  mysql_grant { "${backupuser}@localhost/*.*":
    ensure     => $ensure,
    user       => "${backupuser}@localhost",
    table      => '*.*',
    privileges => $privs,
    require    => Mysql_user["${backupuser}@localhost"],
  }

  if ($clusterbackup == undef) or ($clusterbackup == $::trusted['certname']) {
    cron { 'mysql-backup-binlog-full':
      ensure   => $ensure,
      command  => "flock -w 300 ${backupdir}-lock /usr/local/sbin/mysqlbackup-binlog.sh -f -k ${backuprotate}",
      user     => 'root',
      hour     => $time_full[0],
      minute   => $time_full[1],
      monthday => $time_full[2],
      month    => $time_full[3],
      weekday  => $time_full[4],
      require  => File['mysqlbackup-binlog.sh'],
    }

    cron { 'mysql-backup-binlog-flush':
      ensure   => $ensure,
      command  => "flock -w 5 ${backupdir}-lock /usr/local/sbin/mysqlbackup-binlog.sh -s",
      user     => 'root',
      hour     => $time_flush[0],
      minute   => $time_flush[1],
      monthday => $time_flush[2],
      month    => $time_flush[3],
      weekday  => $time_flush[4],
      require  => File['mysqlbackup-binlog.sh'],
    }

    file { 'mysqlbackup-binlog.sh':
      ensure  => $ensure,
      path    => '/usr/local/sbin/mysqlbackup-binlog.sh',
      mode    => '0700',
      owner   => 'root',
      group   => $mysql::params::root_group,
      content => template("${module_name}/mysqlbackup-binlog.sh.erb"),
    }

    require ::site::backup::backupdir
  }

  #  file { 'mysqlbackupdir':
  #    ensure => 'directory',
  #    path   => $backupdir,
  #    mode   => $backupdirmode,
  #    owner  => $backupdirowner,
  #    group  => $backupdirgroup,
  #  }

}
