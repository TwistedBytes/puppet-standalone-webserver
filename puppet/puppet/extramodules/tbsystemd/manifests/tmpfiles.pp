define tbsystemd::tmpfiles (
  $ensure  = 'present',
  $file,
  $content,
  $file_replace = true,
){
  file { "/etc/tmpfiles.d/${file}":
    ensure  => present,
    content => $content,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    replace => $file_replace,
  }
}