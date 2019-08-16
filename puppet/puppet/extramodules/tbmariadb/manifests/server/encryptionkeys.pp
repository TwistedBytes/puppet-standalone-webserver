define tbmariadb::server::encryptionkeys (
  Integer $number_keys = 4,
  String $path         = '/etc/mysql_encryption',
) {

  $template_values = {
    keypath    => $path,
    numberkeys => $number_keys,
    keyfile    => $name,
  }

  file { 'mysql-create-encryptionkeys.sh':
    path    => '/usr/local/sbin/mysql-create-encryptionkeys.sh',
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => epp("${module_name}/mysql-create-encryptionkeys.sh.epp", $template_values),
  }

  exec { "init postfixadmin database":
    command => "/usr/local/sbin/mysql-create-encryptionkeys.sh",
    creates => "${path}/${name}.enc",
    require => [File["mysql-create-encryptionkeys.sh"]],
  }

}