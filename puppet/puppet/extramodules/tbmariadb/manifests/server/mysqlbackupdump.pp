# @summary
#   Create and manage a MySQL backup.
#
# @example Create a basic MySQL backup:
#   class { 'mysql::server':
#     root_password => 'password'
#   }
#   class { 'mysql::server::backup':
#     backupuser     => 'myuser',
#     backuppassword => 'mypassword',
#     backupdir      => '/tmp/backups',
#   }
#
# @param backupuser
#   MySQL user with backup administrator privileges.
# @param backuppassword
#   Password for `backupuser`.
# @param backupdir
#   Directory to store backup.
# @param backupdirmode
#   Permissions applied to the backup directory. This parameter is passed directly to the file resource.
# @param backupdirowner
#   Owner for the backup directory. This parameter is passed directly to the file resource.
# @param backupdirgroup
#   Group owner for the backup directory. This parameter is passed directly to the file resource.
# @param backupcompress
#   Whether or not to compress the backup (when using the mysqldump provider)
# @param backuprotate
#   Backup rotation interval in 24 hour periods.
# @param ignore_events
#   Ignore the mysql.event table.
# @param delete_before_dump
#   Whether to delete old .sql files before backing up. Setting to true deletes old files before backing up, while setting to false deletes them after backup.
# @param backupdatabases
#   Databases to backup (if using xtrabackup provider).
# @param file_per_database
#   Use file per database mode creating one file per database backup.
# @param include_routines
#   Dump stored routines (procedures and functions) from dumped databases when doing a `file_per_database` backup.
# @param include_triggers
#   Dump triggers for each dumped table when doing a `file_per_database` backup.
# @param ensure
# @param time
#   An array of two elements to set the backup time. Allows ['23', '5'] (i.e., 23:05) or ['3', '45'] (i.e., 03:45) for HH:MM times.
# @param prescript
#   A script that is executed before the backup begins.
# @param postscript
#   A script that is executed when the backup is finished. This could be used to sync the backup to a central store. This script can be either a single line that is directly executed or a number of lines supplied as an array. It could also be one or more externally managed (executable) files.
# @param execpath
#   Allows you to set a custom PATH should your MySQL installation be non-standard places. Defaults to `/usr/bin:/usr/sbin:/bin:/sbin`.
# @param provider
#   Sets the server backup implementation. Valid values are: 
# @param maxallowedpacket
#   Defines the maximum SQL statement size for the backup dump script. The default value is 1MB, as this is the default MySQL Server value.
# @param optional_args
#   Specifies an array of optional arguments which should be passed through to the backup tool. (Supported by the xtrabackup and mysqldump providers.)
#
class tbmariadb::server::mysqlbackupdump (
  $backupuser         = '',
  $backuppassword     = '',
  $backupdir          = '',
  $maxallowedpacket   = '1M',
  $backupdirmode      = '0700',
  $backupdirowner     = 'root',
  $backupdirgroup     = $mysql::params::root_group,
  $backupcompress     = true,
  $backuprotate       = 30,
  $ignore_events      = true,
  $delete_before_dump = false,
  $backupdatabases    = [],
  $file_per_database  = false,
  $include_triggers   = false,
  $include_routines   = false,
  $ensure             = 'present',
  $time               = ['23', '5'],
  $prescript          = false,
  $postscript         = false,
  $execpath           = '/usr/bin:/usr/sbin:/bin:/sbin',
  $optional_args      = [],
) inherits mysql::params {

  if $backupcompress {
    Package['bzip2'] -> File['mysqlbackup.sh']
  }

  mysql_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql::password($backuppassword),
    require       => Class['mysql::server::root_password'],
  }

  if $include_triggers {
    $privs = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS', 'TRIGGER' ]
  } else {
    $privs = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS' ]
  }

  mysql_grant { "${backupuser}@localhost/*.*":
    ensure     => $ensure,
    user       => "${backupuser}@localhost",
    table      => '*.*',
    privileges => $privs,
    require    => Mysql_user["${backupuser}@localhost"],
  }

  cron { 'mysql-backup':
    ensure  => $ensure,
    command => '/usr/local/sbin/mysqlbackup.sh',
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    require => File['mysqlbackup.sh'],
  }

  file { 'mysqlbackup.sh':
    ensure  => $ensure,
    path    => '/usr/local/sbin/mysqlbackup.sh',
    mode    => '0700',
    owner   => 'root',
    group   => $mysql::params::root_group,
    content => template("${module_name}/mysqlbackup-dump.sh.erb"),
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => $backupdirmode,
    owner  => $backupdirowner,
    group  => $backupdirgroup,
  }

}
