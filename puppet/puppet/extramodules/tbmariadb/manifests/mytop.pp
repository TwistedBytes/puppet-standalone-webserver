class tbmariadb::mytop (

) {

  if $::operatingsystem == "CentOS" and (Integer($::os['release']['major']) > 6) {
    ensure_packages(['mytop'])

    $options = $mysql::server::options

    if $mysql::server::create_root_my_cnf == true and $mysql::server::root_password != 'UNSET' {
      file { "${::root_home}/.mytop":
        content => template("${module_name}/mytop.erb"),
        owner   => 'root',
        mode    => '0600',
      }

      # show_diff was added with puppet 3.0
      if versioncmp($::puppetversion, '3.0') <= 0 {
        File["${::root_home}/.mytop"] { show_diff => false }
      }
      if $mysql::server::create_root_user == true {
        Mysql_user['root@localhost'] -> File["${::root_home}/.mytop"]
      }
    }
  }
}