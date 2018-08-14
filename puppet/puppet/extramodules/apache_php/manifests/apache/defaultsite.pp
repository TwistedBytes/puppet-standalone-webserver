class apache_php::apache::defaultsite (
  $phpMyAdminVersion  = undef, # undef or version
  $defaultsiteVersion = undef, # undef or version
  $defaultsiteName    = 'defaultsite',
  $phpMyAdminDlBase   = 'https://files.phpmyadmin.net/phpMyAdmin',
  $vhostprio          = undef,
  $pma_databaseip     = 'localhost',
  $pma_url_path       = 'tb-pma',
  $redisadmin         = false,
  $extra_aliasses     = [],
) {
  $defaultsiteHash = lookup('apache_php::apache::defaultsiteHash', Hash, {"strategy" => "deep", "merge_hash_arrays" => true})
  $site = $defaultsiteHash['default']
  include apache_php::apache

  # $c1 = hiera_hash('apache_php::customers::customers')
  $c1 = lookup('apache_php::customers::customers', Hash, {"strategy" => "deep", "merge_hash_arrays" => true})
  $c2 = $site['customer']

  realize(Apache_php::User[$c2])

  $customerhash = $c1[$c2]
  $vhostname = $site['vhostname']

  $basedir = "${customerhash['homedir']}/${vhostname}/site"

  File <| title == "${basedir}" |> {
    recurse => true,
    purge   => true,
    backup  => false,
    force   => true,
  }

  if ($defaultsiteVersion) {
    tbsite::extract { "${defaultsiteName}-${defaultsiteVersion}.tgz":
      file      => "$basedir/${defaultsiteName}-${defaultsiteVersion}.tgz",
      tarparams => ' --strip-components=1',
      source    => "puppet:///modules/site/defaultsite/${defaultsiteName}-${defaultsiteVersion}.tar.gz",
      targetdir => "${basedir}/defaultsite-${defaultsiteVersion}",
      creates   => "${basedir}/defaultsite-${defaultsiteVersion}/tag.txt",
      purge     => true,
      require   => File[$basedir]
    }

    File <| title == "${basedir}/docroot" |> {
      force   => true,
      backup  => false,
    }

  # need for php docroot
    file { "${basedir}/defaultsite":
      ensure => 'link',
      target => "defaultsite-${defaultsiteVersion}",
    }
  }

  if ($phpMyAdminVersion) {
    $pmalias = "Alias /${pma_url_path} ${basedir}/${pma_url_path}"

    tbsite::extract { "phpMyAdmin-${phpMyAdminVersion}-all-languages.tar.gz":
      file      => "$basedir/phpMyAdmin-${phpMyAdminVersion}-all-languages.tar.gz",
      tarparams => ' --strip-components=1',
      url       => "${phpMyAdminDlBase}/${phpMyAdminVersion}/phpMyAdmin-${phpMyAdminVersion}-all-languages.tar.gz",
      targetdir => "${basedir}/${pma_url_path}-${phpMyAdminVersion}",
      creates   => "${basedir}/${pma_url_path}-${phpMyAdminVersion}/index.php",
      purge     => false,
      require   => File[$basedir],
      notify    => File["${basedir}/${pma_url_path}-${phpMyAdminVersion}/config.inc.php"],
    }

  # need for php docroot
    file { "${basedir}/${pma_url_path}":
      ensure => 'link',
      target => "${pma_url_path}-${phpMyAdminVersion}",
    }

    file { "${basedir}/${pma_url_path}-${phpMyAdminVersion}/config.inc.php":
      ensure  => present,
      content => template('apache_php/phpmyadmin/config.inc.php.erb'),
    }
  }

  if($redisadmin){
    class {apache_php::apache::redisadmin:
      install_path => "${basedir}",
    }
    $redisalias = "Alias /${apache_php::apache::redisadmin::url_path} ${basedir}/${apache_php::apache::redisadmin::url_path}"
  } else {
    $redisalias = undef
  }

  $port = hiera('apache_php::varnish_used::port', undef)

  $ssl = $defaultsiteHash['default']['ssl']

  $newHash = {
    'default' => merge($defaultsiteHash['default'], {
      options    => {
        custom     => join(flatten([$extra_aliasses, [pick($redisalias, ' '), pick($pmalias, ' ')]]), "\n"), # no alias option use because of order can change
        docroot_symlink => true,
        link_to => 'defaultsite',
      },
      pmdefaults => {
        pm         => 'ondemand',
      },
      vhostprio  => pick($vhostprio, $defaultsiteHash['default']['vhostprio'], 25),
      ssl        => $ssl,
    }
    )
  }

  create_resources('apache_php::site', $newHash)

}
