class tbphp::wpcli::auto_update (
  $max_age,
  $source,
  $path,
) {

  if $caller_module_name != $module_name {
    warning("${name} is not part of the public API of the ${module_name} module and should not be directly included in the manifest.")
  }

  exec { 'update wpcli':
    command => "wget ${source} -O ${path}",
    onlyif  => "test `find '${path}' -mtime +${max_age}`",
    path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    require => File[$path],
  }
}
