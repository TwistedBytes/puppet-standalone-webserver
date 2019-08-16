class tbmariadb::server::backup (
  $backuptype     = 'mysqldump',
  $backup_ensure  = 'present',
  $backuprotate   = 5,
  $pwcontext      = $::trusted['certname'],

){
  require ::tbsite::backup::backupdir

  $backup_password = cache_data("cache/${pwcontext}", 'mysql_user_backup', fqdn_rand_string(30))

  if $backuptype == 'mysqldump' {
    class { ::tbmariadb::server::mysqlbackupdump:
      ensure            => $backup_ensure,
      backupuser        => 'backup',
      backuppassword    => $backup_password,
      backupdir         => '/var/backup/mysql',
      backuprotate      => $backuprotate,
      file_per_database => true,
      require           => [File['/var/backup']],
    }
  } elsif $backuptype == 'mysqlbackupbinlog' {
    class { ::tbmariadb::server::mysqlbackupbinlog:
      ensure            => $backup_ensure,
      backupuser        => 'backup',
      backuppassword    => $backup_password,
      backupdir         => '/var/backup/mysql',
      require           => [File['/var/backup'], Package['bzip2']],
    }
  }
}