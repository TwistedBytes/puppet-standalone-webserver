class tbphp::wpcli::wpcli (
  $source      = 'https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar',
  $path        = '/usr/local/bin/wp',
  $auto_update = true,
  $max_age     = 30,
) {

  validate_string($source)
  validate_absolute_path($path)
  validate_bool($auto_update)
  validate_integer($max_age)

  exec { 'download wpcli':
    command => "wget ${source} -O ${path}",
    creates => $path,
    path    => ['/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/'],
  } ->
  file { $path:
    mode  => '0555',
    owner => root,
    group => root,
  }

  if $auto_update {
    class { 'tbphp::wpcli::auto_update':
      max_age => $max_age,
      source  => $source,
      path    => $path
    }
  }
}