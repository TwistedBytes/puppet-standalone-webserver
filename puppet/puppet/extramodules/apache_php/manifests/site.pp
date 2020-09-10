define apache_php::site (
  $ensure                 = 'present',
  $vhostname              = $title,
  $vhost_ip               = undef,
  $serveraliases          = [],
  $vhostprio              = undef,
  $customer               = undef,
  $user_hash              = undef,
  $user_hash_tbpw_context = undef,
  $user_ssh_keys          = undef,
  $user_ssh_purge         = undef,
  $user_ssh_keys_extra    = [],
  $fcgi_port              = undef,
  $databases              = {},
  $database_write_ini     = true,
  $options                = {},
  $php_values_override    = undef,
  $ssl                    = undef,
  $ssl_alts               = undef,
  $aliases                = undef,
  $pmdefaults             = undef,
  $jail_chroot            = false,
  $ssh_login              = false,
  $shell                  = '/bin/bash',
  $uid                    = undef,
  $addclustershare        = false,
  $virtualdocroot         = false,
  $convert_proftpd        = true,
  $create_default_sa      = false,
  $write_backuppath       = undef,
  $log_format_name        = undef,
  $replace_config_var     = false,
  $custom                 = [],
  $htpasswdfile           = undef,
  $vhostbasedir           = undef,
  $vhostparentdir         = undef,
) {

  # username max 32 chars long, cut the end if needed
  $vhost_username = regsubst($vhostname, '^(.{32})(.*)', '\1')

  if $customer != undef {
    $c1 = hiera_hash('apache_php::customers::customers')
    $customerhash = $c1[$customer]

    realize(Apache_php::User[$customer])

    $vhost_usergroup = $customerhash['username']
    $vhost_parentdir = "${customerhash['homedir']}/${vhostname}"

    require ::apache_php::customers
  } else {
    $vhost_usergroup = $vhost_username
    $vhost_parentdir = $vhostparentdir
  }

  $real_user_hash = $user_hash

  $vhost_basedir = $vhostbasedir ? {
    undef   => "${vhost_parentdir}/${vhostname}",
    default => $vhostbasedir,
  }

  apache_php::user { "$vhostname":
    ensure              => $ensure,
    homedir             => $vhost_basedir,
    username            => $vhost_username,
    gid                 => $vhost_usergroup,
    uid                 => $uid,
    user_hash           => $real_user_hash,
    user_ssh_purge      => $user_ssh_purge,
    user_ssh_keys       => $user_ssh_keys,
    user_ssh_keys_extra => $user_ssh_keys_extra,
    convert_proftpd     => $convert_proftpd,
  }

  if ($ensure == 'present') {
    apache_php::tbsite::dirstructure { $vhostname:
      basedir   => $vhost_parentdir,
      vhostname => $vhostname,
      uid       => $vhost_username,
      gid       => $vhost_usergroup,
    }

    $require_dirstructure = Apache_php::Tbsite::Dirstructure[$vhostname]
  } else {
    $require_dirstructure = undef
  }

  $real_serveraliases = $serveraliases

  $servertype = pick($options['servertype'], 'apache')
  $usephp = pick($options['php'], true)
  $phptype = pick($options['phptype'], 'php')
  $docroot_symlink = pick($options['docroot_symlink'], false)
  $followsymlinks = pick($options['followsymlinks'], 'SymLinksIfOwnerMatch')

  $apachenew = hiera('apache_php::apachenew', false)

  if($apachenew or $servertype == 'nginx') {
    $php7 = pick($options['php7'], false)
    $fcgi_listen = "/var/run/php-fpm/${vhostname}.sock"

    if $php7 {
      require ::tbphp::php7X::phpswitcher

      case $php7 {
        /^\d+$/, 70, 71, 72, 73, 74: {
          $php7version = $php7
        }
        true: {
          $php7version = 70
        }
      }

      if $php7version == 70 {
        include tbphp::php7::phpfpm
      } else {
        if !defined(Tbphp::Php7x::Phpfpm["${php7version}"]) {
          tbphp::php7x::phpfpm { "${php7version}": }
        }
      }

      $php7_switcher_fcgi_listen = "${tbphp::php7x::phpswitcher::socket_switch_dir}/${vhostname}.sock"

      $phpswitchscript = "${vhost_basedir}/private/bin/phpswitch.sh"
      file { $phpswitchscript:
        ensure  => 'file',
        owner   => $vhost_username,
        group   => $vhost_usergroup,
        mode    => '0700',
        content => template("${module_name}/switch-php.sh.erb"),
        require => $require_dirstructure,
      }

      sudo::conf { "${vhost_username}-phpswitcher":
        priority => 10,
        content  => "${vhost_username} ALL=(ALL) NOPASSWD: ${phpswitchscript}",
      }

      $php_default_version = pick($options['php_default'], '56')
      $php_default_force = pick($options['php_default_force'], false)

      case $php_default_version {
        /^\d+$/, 70, 71, 72, 73, 74: {
          $fcgi_listen_sock = "/var/opt/remi/php${php_default_version}/run/php-fpm/${vhostname}.sock"
          $userbin_link = "/usr/bin/php${php_default_version}"
        }
        56: {
          $fcgi_listen_sock = $fcgi_listen
          $userbin_link = '/usr/bin/php'
        }
      }

      if $php_default_force {
        $php7_switcher_replace = true
      } else {
        $php7_switcher_replace = false
      }

      file { $php7_switcher_fcgi_listen:
        ensure  => 'link',
        replace => $php7_switcher_replace,
        target  => $fcgi_listen_sock,
      }

      file { "${vhost_basedir}/private/bin/php":
        ensure  => 'link',
        replace => $php7_switcher_replace,
        owner   => $vhost_username,
        group   => $vhost_usergroup,
        target  => $userbin_link,
      }

      if $ensure == 'absent' {
        File <| title == $phpswitchscript |> {
          ensure => 'absent',
        }
        File <| title == $php7_switcher_fcgi_listen |> {
          ensure  => 'absent',
          replace => true,
        }
        File <| title == "${vhost_basedir}/private/bin/php" |> {
          ensure  => 'absent',
          replace => true,
        }
        Sudo::Conf <| title == "${vhost_username}-phpswitcher" |> {
          ensure => 'absent',
        }
      }

      $apache_fcgi = "unix:${php7_switcher_fcgi_listen}|fcgi://${vhostname}"
      $nginx_fcgi = "unix:${php7_switcher_fcgi_listen}"
    } else {
      $apache_fcgi = "unix:${fcgi_listen}|fcgi://${vhostname}"
      $nginx_fcgi = "unix:${fcgi_listen}"
    }
  } else {
    $fcgi_listen = "127.0.0.1:${fcgi_port}"
    $apache_fcgi = "fcgi://${fcgi_listen}"
    $nginx_fcgi = $fcgi_listen
  }
  if ($ensure == 'present') {

    if ($servertype == 'apache') {
      include apache_php::apache

      $phpproxytimout = pick($options['phpproxytimout'], 600)

      apache_php::apachevhost { "$vhostname@${::fqdn}":
        vhostname          => $vhostname,
        ip                 => $vhost_ip,
        priority           => $vhostprio,
        serveraliases      => $real_serveraliases,
        vhostbase          => $vhost_basedir,
        require            => $require_dirstructure,
        uid                => $vhost_username,
        gid                => $vhost_usergroup,
        ssl                => $ssl,
        ssl_alts           => $ssl_alts,
        aliases            => $aliases,
        virtualdocroot     => $virtualdocroot,
        followsymlinks     => $followsymlinks,
        proxy_timeout      => $phpproxytimout,
        docroot_mode       => pick($options['docroot_mode'], '0755'),
        log_format_name    => $log_format_name,
        custom             => $custom,
        replace_config_var => $replace_config_var,
        htpasswdfile       => $htpasswdfile,
        options            => {
          php             => $usephp,
          php_fcgi        => $apache_fcgi,
          frameworkconfig => pick($options['frameworkconfig'], 'none'),
          custom          => pick($options['custom'], ' '),
          docroot_symlink => $docroot_symlink,
          link_to         => pick($options['link_to'], false),
          blockrobots     => pick($options['blockrobots'], false),
        },
      }
    }
  }

  if ($usephp == true) {
    if $phptype == 'php' {

      if ($ensure == 'absent') {
        Apache_php::Phpfpmvhost <| title == "$vhostname@${::fqdn}" |> -> Apache_php::User<| title == "$vhostname" |>
      }

      $phpreusepoolport = pick($options['phpreusepoolport'], false)
      if (!$phpreusepoolport) {

        apache_php::phpfpmvhost { "$vhostname@${::fqdn}":
          ensure                => $ensure,
          vhostname             => $vhostname,
          listen                => $fcgi_listen,
          vhostbase             => $vhost_basedir,
          runasuid              => $vhost_username,
          runasgid              => $vhost_usergroup,
          require               => $require_dirstructure,
          pmdefaults            => $pmdefaults,
          php_values_override   => $php_values_override,
          php7                  => $php7,
          php7_switcher_replace => $php7_switcher_replace,
        }
      }
    }

    if $ssh_login == true {
      if $php7 {
        $cli_socket = "${tbphp::php7x::phpswitcher::socket_switch_dir}/${vhostname}.sock"
      } else {
        $cli_socket = $fcgi_listen
      }

      ::tbphp::php_fpm_cli { "${vhost_basedir}/private/bin/php-fpm-cli":
        ensure       => $ensure,
        phpfpmsocket => $cli_socket,
        tmpdir       => "${vhost_basedir}/private/php-tmp",
        uid          => $vhost_username,
        gid          => $vhost_usergroup,
      }
    }

    tbuser::shellconfig { $vhost_username:
      ensure  => $ensure,
      homedir => "${vhost_basedir}",
      owner   => $vhost_username,
      group   => $vhost_usergroup,
      require => Apache_php::User["$vhostname"]
    }
    User <| title == $vhost_username |> {
      shell => $shell,
    }
  }

  validate_hash($databases)
  if (!empty($databases)) {

    if $ensure == 'present' {
      if $database_write_ini {
        $database_ini = "${vhost_basedir}/private/databases.ini"

        concat { $database_ini:
          owner  => $vhost_username,
          group  => $vhost_usergroup,
          mode   => '0400',
          ensure => $ensure,
        }
      }
    } else {
      $database_ini = undef
    }
    $dbdefaults = {
      ensure   => $ensure,
      ini_file => $database_ini,
    }

    create_resources('apache_php::db::simple', $databases, $dbdefaults)
  }

}
