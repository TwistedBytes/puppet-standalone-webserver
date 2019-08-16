# this converts the database to utf8mb4 instead of utf8
# see https://mathiasbynens.be/notes/mysql-utf8mb4

class tbmariadb::converttoutf8mb4 (
  $breadcrumb = '/etc/my.cnf.d/updated-to-utf8mb4'
) {
  file { '/usr/local/sbin/mysql-utf8mb4-fix.sh':
    ensure => 'file',
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
    source => "puppet:///modules/${module_name}/mysql-utf8mb4-fix.sh",
  }

  exec { "mysql-utf8mb4-fix.sh":
    command     => "/usr/local/sbin/mysql-utf8mb4-fix.sh",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    require     => File['/usr/local/sbin/mysql-utf8mb4-fix.sh'],
    creates     => $breadcrumb,
    refreshonly => true,
    subscribe   => File[$breadcrumb],
  }

  file { $breadcrumb: content => "#updated, do not remove. otherwise will convert db again." }
}
